module JazzStandards exposing (script)

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import BackendTask.Http
import Serialize
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Kit
import Kit.Db
import Kit.Script as Script


type alias Track =
    { name : String
    , artist : String
    , album : String
    , albumArt : String
    , spotifyUrl : String
    }


playlistId : String
playlistId =
    "1x7TzCfKamyyOoR5OC7Nxn"


script : Script.Script
script =
    Script.define
        { name = "Jazz Standards"
        , task = task
        }
        |> Script.withDescription "Search Ted Gioia's Jazz Standards playlist"
        |> Script.withShortcut "cmd+shift+j"


task : BackendTask FatalError ()
task =
    getTracks
        |> BackendTask.andThen selectTrack
        |> BackendTask.andThen showTrack


getTracks : BackendTask FatalError (List Track)
getTracks =
    Kit.Db.getOrFetch "jazz-standards"
        (Serialize.list trackCodec)
        (getAccessToken |> BackendTask.andThen fetchAllTracks)


getAccessToken : BackendTask FatalError String
getAccessToken =
    BackendTask.Custom.run "spotifyGetAccessToken"
        Encode.null
        Decode.string
        |> BackendTask.allowFatal


fetchAllTracks : String -> BackendTask FatalError (List Track)
fetchAllTracks accessToken =
    fetchTracksPage accessToken 0 []


fetchTracksPage : String -> Int -> List Track -> BackendTask FatalError (List Track)
fetchTracksPage accessToken offset accumulated =
    let
        limit =
            100

        url =
            "https://api.spotify.com/v1/playlists/"
                ++ playlistId
                ++ "/tracks?limit="
                ++ String.fromInt limit
                ++ "&offset="
                ++ String.fromInt offset
                ++ "&market=US"
    in
    BackendTask.Http.getWithOptions
        { url = url
        , expect = BackendTask.Http.expectJson playlistResponseDecoder
        , headers = [ ( "Authorization", "Bearer " ++ accessToken ) ]
        , cacheStrategy = Nothing
        , retries = Just 0
        , timeoutInMs = Just 60000
        , cachePath = Nothing
        }
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\response ->
                let
                    newAccumulated =
                        accumulated ++ response.tracks
                in
                if response.hasMore then
                    fetchTracksPage accessToken (offset + limit) newAccumulated

                else
                    BackendTask.succeed newAccumulated
            )


type alias PlaylistResponse =
    { tracks : List Track
    , hasMore : Bool
    }


playlistResponseDecoder : Decoder PlaylistResponse
playlistResponseDecoder =
    Decode.map2 PlaylistResponse
        (Decode.field "items" (Decode.list trackItemDecoder)
            |> Decode.map (List.filterMap identity)
        )
        (Decode.field "next" (Decode.nullable Decode.string)
            |> Decode.map (\next -> next /= Nothing)
        )


trackItemDecoder : Decoder (Maybe Track)
trackItemDecoder =
    Decode.field "track"
        (Decode.nullable
            (Decode.map2 Tuple.pair
                (Decode.field "is_playable" Decode.bool
                    |> Decode.maybe
                    |> Decode.map (Maybe.withDefault True)
                )
                trackDecoder
            )
        )
        |> Decode.map
            (\maybeTrackInfo ->
                maybeTrackInfo
                    |> Maybe.andThen
                        (\( isPlayable, track ) ->
                            if isPlayable then
                                Just track

                            else
                                Nothing
                        )
            )


trackDecoder : Decoder Track
trackDecoder =
    Decode.map5 Track
        (Decode.field "name" Decode.string)
        (Decode.at [ "artists" ] (Decode.index 0 (Decode.field "name" Decode.string))
            |> Decode.maybe
            |> Decode.map (Maybe.withDefault "Unknown Artist")
        )
        (Decode.at [ "album", "name" ] Decode.string)
        (Decode.at [ "album", "images" ]
            (Decode.index 0 (Decode.field "url" Decode.string))
            |> Decode.maybe
            |> Decode.map (Maybe.withDefault "")
        )
        (Decode.at [ "external_urls", "spotify" ] Decode.string
            |> Decode.maybe
            |> Decode.map (Maybe.withDefault "")
        )



trackCodec : Serialize.Codec e Track
trackCodec =
    Serialize.record Track
        |> Serialize.field .name Serialize.string
        |> Serialize.field .artist Serialize.string
        |> Serialize.field .album Serialize.string
        |> Serialize.field .albumArt Serialize.string
        |> Serialize.field .spotifyUrl Serialize.string
        |> Serialize.finishRecord


selectTrack : List Track -> BackendTask FatalError Track
selectTrack tracks =
    Kit.arg
        { placeholder = "Search jazz standards..."
        , choices =
            List.map
                (\track ->
                    { name = track.name
                    , value = track.spotifyUrl
                    , description = track.artist ++ " — " ++ track.album
                    , img = Just track.albumArt
                    }
                )
                tracks
        }
        |> BackendTask.andThen
            (\selectedUrl ->
                case List.filter (\t -> t.spotifyUrl == selectedUrl) tracks of
                    track :: _ ->
                        BackendTask.succeed track

                    [] ->
                        BackendTask.fail (FatalError.fromString "Track not found")
            )


showTrack : Track -> BackendTask FatalError ()
showTrack track =
    let
        -- Extract track ID from URL like https://open.spotify.com/track/4LvfubODyhMUPz1amROlUN?si=...
        trackId =
            track.spotifyUrl
                |> String.split "/"
                |> List.reverse
                |> List.head
                |> Maybe.withDefault ""
                |> String.split "?"
                |> List.head
                |> Maybe.withDefault ""

        -- Format: spotify:track:<track_id>?context=spotify:playlist:<playlist>
        spotifyUri =
            "spotify:track:" ++ trackId ++ "?context=spotify:playlist:" ++ playlistId
    in
    Kit.open spotifyUri
