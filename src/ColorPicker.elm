module ColorPicker exposing (run)

import BackendTask exposing (BackendTask)
import Html.String as Html
import Html.String.Attributes
import Kit
import Pages.Script as Script exposing (Script)


run : Script
run =
    Kit.script
        (Kit.arg
            { placeholder = "Choose a color"
            , choices =
                [ { name = "[R]ed", value = "red" }
                , { name = "[G]reen", value = "green" }
                , { name = "[B]lue", value = "blue" }
                ]
            }
            |> BackendTask.andThen
                (\color ->
                    Kit.div
                        (Html.h1
                            [ Html.String.Attributes.class <|
                                "p-10 text-4xl text-center text-"
                                    ++ color
                                    ++ "-400"
                            ]
                            [ Html.text ("You chose " ++ color) ]
                        )
                )
        )
