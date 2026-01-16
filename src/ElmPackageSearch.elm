module ElmPackageSearch exposing (script)

import BackendTask exposing (BackendTask)
import BackendTask.Http
import FatalError exposing (FatalError)
import Html.String as Html
import Html.String.Attributes as Attr
import Json.Decode as Decode exposing (Decoder)
import Kit
import Kit.Script as Script


type alias Package =
    { name : String
    , summary : String
    , version : String
    }


script : Script.Script
script =
    Script.define
        { name = "Elm Package Search"
        , task = task
        }
        |> Script.withDescription "Search and explore Elm packages"


task : BackendTask FatalError ()
task =
    fetchAllPackages
        |> BackendTask.andThen selectPackage
        |> BackendTask.andThen showPackage


fetchAllPackages : BackendTask FatalError (List Package)
fetchAllPackages =
    BackendTask.Http.getWithOptions
        { url = "https://package.elm-lang.org/search.json"
        , expect = BackendTask.Http.expectJson (Decode.list packageDecoder)
        , headers = []
        , cacheStrategy = Nothing
        , retries = Just 0
        , timeoutInMs = Just 60000
        , cachePath = Just ".elm-pkg-cache"
        }
        |> BackendTask.allowFatal


packageDecoder : Decoder Package
packageDecoder =
    Decode.map3 Package
        (Decode.field "name" Decode.string)
        (Decode.field "summary" Decode.string)
        (Decode.field "version" Decode.string)


selectPackage : List Package -> BackendTask FatalError Package
selectPackage packages =
    Kit.arg
        { placeholder = "Search Elm packages..."
        , choices =
            List.map
                (\pkg ->
                    { name = pkg.name
                    , value = pkg.name
                    , description = pkg.summary
                    }
                )
                packages
        }
        |> BackendTask.andThen
            (\selectedName ->
                case List.filter (\p -> p.name == selectedName) packages of
                    pkg :: _ ->
                        BackendTask.succeed pkg

                    [] ->
                        BackendTask.fail (FatalError.fromString "Package not found")
            )


showPackage : Package -> BackendTask FatalError ()
showPackage package =
    let
        installCmd : String
        installCmd =
            "elm install " ++ package.name

        docsUrl : String
        docsUrl =
            "https://package.elm-lang.org/packages/" ++ package.name ++ "/latest/"
    in
    Kit.copy installCmd
        |> BackendTask.andThen
            (\() ->
                Kit.div
                    (Html.div [ Attr.class "p-8 space-y-6" ]
                        [ Html.a
                            [ Attr.href docsUrl
                            , Attr.class "flex items-center gap-3 hover:opacity-80"
                            ]
                            [ Html.div [ Attr.class "text-4xl" ] [ Html.text "📦" ]
                            , Html.h1 [ Attr.class "text-3xl font-bold text-blue-600" ]
                                [ Html.text package.name ]
                            ]
                        , Html.div [ Attr.class "flex items-center gap-2" ]
                            [ Html.span
                                [ Attr.class "px-2 py-1 bg-green-100 text-green-700 rounded-full text-sm font-medium" ]
                                [ Html.text ("v" ++ package.version) ]
                            ]
                        , Html.p [ Attr.class "text-lg text-gray-600" ]
                            [ Html.text package.summary ]
                        , Html.div [ Attr.class "mt-4 p-4 bg-gray-900 rounded-lg" ]
                            [ Html.code [ Attr.class "text-green-400 font-mono" ]
                                [ Html.text installCmd ]
                            ]
                        , Html.p [ Attr.class "text-sm text-gray-500" ]
                            [ Html.text "✓ Copied to clipboard!" ]
                        ]
                    )
            )
