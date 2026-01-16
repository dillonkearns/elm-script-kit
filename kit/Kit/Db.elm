module Kit.Db exposing (get, getOrFetch, write, clear)

{-| Persistent storage using ScriptKit's db API.

Data is stored in `~/.kenv/db/{name}.json`.

Uses [elm-serialize](https://package.elm-lang.org/packages/MartinSStewart/elm-serialize/latest/)
for type-safe serialization.


# Reading

@docs get, getOrFetch


# Writing

@docs write, clear

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode as Decode
import Json.Encode as Encode
import Serialize exposing (Codec)


{-| Get data from a named database. Returns `Nothing` if the database
doesn't exist or has no data.

    Kit.Db.get "todos" (Serialize.list todoCodec)
        |> BackendTask.map (Maybe.withDefault [])

Fails with a `FatalError` if data exists but cannot be decoded (e.g., schema changed).

-}
get : String -> Codec e a -> BackendTask FatalError (Maybe a)
get name codec =
    BackendTask.Custom.run "scriptKitDbGet"
        (Encode.object
            [ ( "name", Encode.string name )
            ]
        )
        (Decode.nullable Decode.value)
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\maybeJson ->
                case maybeJson of
                    Nothing ->
                        -- Cache miss - no data stored
                        BackendTask.succeed Nothing

                    Just json ->
                        -- Data exists, try to decode
                        case Serialize.decodeFromJson codec json of
                            Ok value ->
                                BackendTask.succeed (Just value)

                            Err err ->
                                BackendTask.fail
                                    (FatalError.fromString
                                        ("Failed to decode db '" ++ name ++ "': " ++ serializeErrorToString err)
                                    )
            )


{-| Get data from a named database, or fetch it if not present.

This is the async initializer pattern - perfect for caching:

    getTracks : BackendTask FatalError (List Track)
    getTracks =
        Kit.Db.getOrFetch "jazz-standards"
            (Serialize.list trackCodec)
            fetchTracksFromSpotify

If the database exists and has data, returns it immediately.
If not, runs the provided task, stores the result, and returns it.

-}
getOrFetch : String -> Codec e a -> BackendTask FatalError a -> BackendTask FatalError a
getOrFetch name codec fetchTask =
    get name codec
        |> BackendTask.andThen
            (\maybeData ->
                case maybeData of
                    Just data ->
                        BackendTask.succeed data

                    Nothing ->
                        fetchTask
                            |> BackendTask.andThen
                                (\fetched ->
                                    write name codec fetched
                                        |> BackendTask.map (\() -> fetched)
                                )
            )


{-| Write data to a named database. Replaces entire contents.

    Kit.Db.write "todos" (Serialize.list todoCodec) myTodos

-}
write : String -> Codec e a -> a -> BackendTask FatalError ()
write name codec data =
    BackendTask.Custom.run "scriptKitDbWrite"
        (Encode.object
            [ ( "name", Encode.string name )
            , ( "data", Serialize.encodeToJson codec data )
            ]
        )
        (Decode.null ())
        |> BackendTask.allowFatal


{-| Delete a database file.

    Kit.Db.clear "jazz-standards"

-}
clear : String -> BackendTask FatalError ()
clear name =
    BackendTask.Custom.run "scriptKitDbClear"
        (Encode.object
            [ ( "name", Encode.string name )
            ]
        )
        (Decode.null ())
        |> BackendTask.allowFatal



-- HELPERS


serializeErrorToString : Serialize.Error e -> String
serializeErrorToString err =
    case err of
        Serialize.CustomError _ ->
            "Custom codec error"

        Serialize.DataCorrupted ->
            "Data corrupted"

        Serialize.SerializerOutOfDate ->
            "Serializer out of date - the data schema may have changed. Try clearing the cache with Kit.Db.clear."
