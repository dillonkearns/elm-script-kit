module Kit.Db exposing (get, write)

{-| Simple persistent JSON database using ScriptKit's db API.

Data is stored in `~/.kenv/db/{name}.json`.


# Reading and Writing

@docs get, write

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| Get data from a named database. If the database doesn't exist,
it will be created with the provided default value.

    Kit.Db.get "jazz-standards"
        (Decode.list trackDecoder)
        []

-}
get : String -> Decoder a -> a -> (a -> Encode.Value) -> BackendTask FatalError a
get name decoder defaultValue encoder =
    BackendTask.Custom.run "scriptKitDbGet"
        (Encode.object
            [ ( "name", Encode.string name )
            , ( "defaultData", encoder defaultValue )
            ]
        )
        decoder
        |> BackendTask.allowFatal


{-| Write data to a named database.

    Kit.Db.write "jazz-standards" (Encode.list encodeTrack tracks)

-}
write : String -> Encode.Value -> BackendTask FatalError ()
write name data =
    BackendTask.Custom.run "scriptKitDbWrite"
        (Encode.object
            [ ( "name", Encode.string name )
            , ( "data", data )
            ]
        )
        (Decode.null ())
        |> BackendTask.allowFatal
