module Kit.Field exposing
    ( Fields
    , fields
    , withField
    , withNumberField
    , runFields
    , FieldSpec
    )

{-| Type-safe multi-field form builder for ScriptKit.

    import Kit.Field as Field

    type alias Person =
        { name : String
        , email : String
        , age : Float
        }

    Field.fields (\name email age -> { name = name, email = email, age = age })
        |> Field.withField "Name"
        |> Field.withField "Email"
        |> Field.withNumberField "Age"
        |> Field.runFields

@docs Fields, fields, withField, withNumberField, runFields, FieldSpec

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode as Decode
import Json.Encode as Encode


{-| Builder for a multi-field form. Uses an applicative pattern for type safety.
-}
type Fields a
    = Fields
        { specs : List FieldSpec
        , decoder : Decode.Decoder a
        }


{-| Specification for a single field.
-}
type alias FieldSpec =
    { label : String
    , fieldType : String
    }


{-| Start building a multi-field form with a constructor function.

    Field.fields (\name email age -> { name = name, email = email, age = age })
        |> Field.withField "Name"
        |> Field.withField "Email"
        |> Field.withNumberField "Age"
        |> Field.runFields

-}
fields : a -> Fields a
fields constructor =
    Fields
        { specs = []
        , decoder = Decode.succeed constructor
        }


{-| Add a text field to the form. Applies a String to the constructor.
-}
withField : String -> Fields (String -> a) -> Fields a
withField label (Fields f) =
    Fields
        { specs = f.specs ++ [ { label = label, fieldType = "text" } ]
        , decoder =
            Decode.map2 (<|)
                f.decoder
                (Decode.index (List.length f.specs) Decode.string)
        }


{-| Add a number field to the form. Applies a Float to the constructor.
-}
withNumberField : String -> Fields (Float -> a) -> Fields a
withNumberField label (Fields f) =
    let
        floatDecoder =
            Decode.string
                |> Decode.andThen
                    (\s ->
                        case String.toFloat s of
                            Just n ->
                                Decode.succeed n

                            Nothing ->
                                Decode.fail ("Expected a number but got: " ++ s)
                    )
    in
    Fields
        { specs = f.specs ++ [ { label = label, fieldType = "number" } ]
        , decoder =
            Decode.map2 (<|)
                f.decoder
                (Decode.index (List.length f.specs) floatDecoder)
        }


{-| Run the fields form and get the results.
-}
runFields : Fields a -> BackendTask FatalError a
runFields (Fields f) =
    BackendTask.Custom.run "scriptKitFields"
        (Encode.list encodeFieldSpec f.specs)
        f.decoder
        |> BackendTask.allowFatal


encodeFieldSpec : FieldSpec -> Encode.Value
encodeFieldSpec spec =
    Encode.object
        [ ( "label", Encode.string spec.label )
        , ( "type", Encode.string spec.fieldType )
        ]
