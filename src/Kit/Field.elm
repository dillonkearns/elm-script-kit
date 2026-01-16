module Kit.Field exposing
    ( Fields
    , fields
    , with
    , runFields
      -- Field Constructors
    , FieldConfig
    , text
    , int
    , number
    , email
    , textarea
      -- Modifiers
    , placeholder
    , required
    , withDefault
    , min
    , max
    )

{-| Type-safe multi-field form builder for ScriptKit.

    import Kit.Field as Field

    type alias Person =
        { name : String
        , bio : String
        , age : Int
        }

    Field.fields Person
        |> Field.with (Field.text "Name" |> Field.placeholder "Enter name")
        |> Field.with (Field.textarea "Bio" { rows = 4 })
        |> Field.with (Field.int "Age" |> Field.min 0 |> Field.max 120)
        |> Field.runFields


# Builder

@docs Fields, fields, with, runFields


# Field Constructors

@docs FieldConfig, text, int, number, email, textarea


# Modifiers

@docs placeholder, required, withDefault, min, max

-}

import BackendTask exposing (BackendTask)
import BackendTask.Custom
import FatalError exposing (FatalError)
import Json.Decode as Decode
import Json.Encode as Encode



-- FIELDS BUILDER


{-| Builder for a multi-field form.
-}
type Fields a
    = Fields
        { specs : List FieldSpec
        , decoder : Decode.Decoder a
        }


{-| Start building a multi-field form with a constructor function.

    Field.fields (\name age -> { name = name, age = age })
        |> Field.with (Field.text "Name")
        |> Field.with (Field.int "Age")
        |> Field.runFields

-}
fields : a -> Fields a
fields constructor =
    Fields
        { specs = []
        , decoder = Decode.succeed constructor
        }


{-| Add a field to the form.
-}
with : FieldConfig a -> Fields (a -> b) -> Fields b
with (FieldConfig config) (Fields f) =
    Fields
        { specs = f.specs ++ [ config.spec ]
        , decoder =
            Decode.map2 (<|)
                f.decoder
                (Decode.index (List.length f.specs) config.decoder)
        }


{-| Run the fields form and get the results.
-}
runFields : Fields a -> BackendTask FatalError a
runFields (Fields f) =
    BackendTask.Custom.run "scriptKitFields"
        (Encode.list encodeFieldSpec f.specs)
        f.decoder
        |> BackendTask.allowFatal



-- FIELD CONFIG


{-| Configuration for a single field.
-}
type FieldConfig a
    = FieldConfig
        { spec : FieldSpec
        , decoder : Decode.Decoder a
        }


type alias FieldSpec =
    { label : String
    , fieldType : String
    , element : String
    , placeholder : Maybe String
    , required : Bool
    , defaultValue : Maybe String
    , minValue : Maybe Int
    , maxValue : Maybe Int
    , step : Maybe String
    , rows : Maybe Int
    , options : List String
    }


defaultSpec : String -> FieldSpec
defaultSpec label =
    { label = label
    , fieldType = "text"
    , element = "input"
    , placeholder = Nothing
    , required = False
    , defaultValue = Nothing
    , minValue = Nothing
    , maxValue = Nothing
    , step = Nothing
    , rows = Nothing
    , options = []
    }



-- FIELD CONSTRUCTORS


{-| A text input field.

    Field.text "Name"

-}
text : String -> FieldConfig String
text label =
    FieldConfig
        { spec = defaultSpec label
        , decoder = Decode.string
        }


{-| An integer input field. Validates that the input is a whole number.

    Field.int "Age"

-}
int : String -> FieldConfig Int
int label =
    let
        spec =
            defaultSpec label

        intDecoder =
            Decode.string
                |> Decode.andThen
                    (\s ->
                        case String.toInt s of
                            Just n ->
                                Decode.succeed n

                            Nothing ->
                                Decode.fail ("Expected an integer but got: " ++ s)
                    )
    in
    FieldConfig
        { spec = { spec | fieldType = "number", step = Just "1" }
        , decoder = intDecoder
        }


{-| A number input field. Returns a Float.

    Field.number "Price"

-}
number : String -> FieldConfig Float
number label =
    let
        spec =
            defaultSpec label

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
    FieldConfig
        { spec = { spec | fieldType = "number" }
        , decoder = floatDecoder
        }


{-| An email input field. Browser will validate email format.

    Field.email "Email"

-}
email : String -> FieldConfig String
email label =
    let
        spec =
            defaultSpec label
    in
    FieldConfig
        { spec = { spec | fieldType = "email" }
        , decoder = Decode.string
        }


{-| A multi-line textarea field.

    Field.textarea "Bio" { rows = 4 }

-}
textarea : String -> { rows : Int } -> FieldConfig String
textarea label options =
    let
        spec =
            defaultSpec label
    in
    FieldConfig
        { spec = { spec | element = "textarea", rows = Just options.rows }
        , decoder = Decode.string
        }





-- MODIFIERS


{-| Add placeholder text to a field.

    Field.text "Name"
        |> Field.placeholder "Enter your name"

-}
placeholder : String -> FieldConfig a -> FieldConfig a
placeholder value (FieldConfig config) =
    FieldConfig
        { config | spec = setPlaceholder value config.spec }


setPlaceholder : String -> FieldSpec -> FieldSpec
setPlaceholder value spec =
    { spec | placeholder = Just value }


{-| Mark a field as required.

    Field.text "Name"
        |> Field.required

-}
required : FieldConfig a -> FieldConfig a
required (FieldConfig config) =
    FieldConfig
        { config | spec = setRequired config.spec }


setRequired : FieldSpec -> FieldSpec
setRequired spec =
    { spec | required = True }


{-| Set a default value for a field.

    Field.text "Country"
        |> Field.withDefault "USA"

-}
withDefault : String -> FieldConfig a -> FieldConfig a
withDefault value (FieldConfig config) =
    FieldConfig
        { config | spec = setDefault value config.spec }


setDefault : String -> FieldSpec -> FieldSpec
setDefault value spec =
    { spec | defaultValue = Just value }


{-| Set minimum value for an int field.

    Field.int "Age"
        |> Field.min 0

-}
min : Int -> FieldConfig Int -> FieldConfig Int
min value (FieldConfig config) =
    FieldConfig
        { config | spec = setMin value config.spec }


setMin : Int -> FieldSpec -> FieldSpec
setMin value spec =
    { spec | minValue = Just value }


{-| Set maximum value for an int field.

    Field.int "Age"
        |> Field.max 120

-}
max : Int -> FieldConfig Int -> FieldConfig Int
max value (FieldConfig config) =
    FieldConfig
        { config | spec = setMax value config.spec }


setMax : Int -> FieldSpec -> FieldSpec
setMax value spec =
    { spec | maxValue = Just value }



-- ENCODERS


encodeFieldSpec : FieldSpec -> Encode.Value
encodeFieldSpec spec =
    Encode.object
        ([ ( "label", Encode.string spec.label )
         , ( "type", Encode.string spec.fieldType )
         , ( "element", Encode.string spec.element )
         , ( "required", Encode.bool spec.required )
         ]
            ++ encodeMaybe "placeholder" Encode.string spec.placeholder
            ++ encodeMaybe "value" Encode.string spec.defaultValue
            ++ encodeMaybe "min" Encode.int spec.minValue
            ++ encodeMaybe "max" Encode.int spec.maxValue
            ++ encodeMaybe "step" Encode.string spec.step
            ++ encodeMaybe "rows" Encode.int spec.rows
            ++ (if List.isEmpty spec.options then
                    []

                else
                    [ ( "options", Encode.list Encode.string spec.options ) ]
               )
        )


encodeMaybe : String -> (a -> Encode.Value) -> Maybe a -> List ( String, Encode.Value )
encodeMaybe key encoder maybeValue =
    case maybeValue of
        Just value ->
            [ ( key, encoder value ) ]

        Nothing ->
            []
