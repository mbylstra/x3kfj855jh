module Orchestrator where

--------------------------------------------------------------------------------
-- EXTERNAL DEPENDENCIES
--------------------------------------------------------------------------------

import Dict exposing (Dict)
import ElmTest exposing (..)


--------------------------------------------------------------------------------
-- INTERNAL DEPENDENCIES
--------------------------------------------------------------------------------

import Audio.MainTypes exposing (..)

import Audio.Atoms.Sine exposing (sinWave)
    -- ( squareWave
    -- , simpleLowPassFilter
    -- , sawWave
    -- , OscillatorType(Square, Saw, Triangle)
    -- , oscillator
    -- , sine
    -- , OscillatorF
    -- , gain
    -- , GainF
    -- , OutputFloat
    -- )

import Gui exposing (EncodedModel)
--------------------------------------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------------------------------------




type alias ExternalState =
    { time : Float
    , externalInputState : EncodedModel
    }

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------


-- updateGraph : DictGraph -> ExternalState -> (DictGraph, OutputFloat)
updateGraph : DictGraph -> ExternalState -> (DictGraph, OutputFloat)
updateGraph graph externalState =
{-     let
        _ = Debug.log "externalState" externalState
    in -}
    updateGraphNode graph externalState (getDestinationNode graph)

{- updateGraph graph externalState =
    (graph, externalState) -}


{- this naming is pretty gross! Difference is it takes an Input rather than an AudioNode -}
-- updateGraphNode' : DictGraph -> TimeFloat -> Input -> (DictGraph, Float)

updateGraphNode' : DictGraph -> ExternalState -> Input -> (DictGraph, OutputFloat)
updateGraphNode' graph externalState input =
    case input of
        ID id ->
            updateGraphNode graph externalState (getInputNode graph id)
        Value v ->
            (graph, v)
        Default ->
            (graph, 0.0) -- need to work out how to send defaults around
        Node x ->
            Debug.crash "Node not supported yet"
        GUI x ->
            Debug.crash "GUI not supported yet"
        -- Multiply _ ->
        --     Debug.crash "Multiply not supported yet"


updateGraphNode : DictGraph -> ExternalState -> AudioNode -> (DictGraph, OutputFloat)
updateGraphNode graph externalState node =

    case node of

        -- this requires a lot of rework to support inputs!
        -- it will be much easier with an actuall record for inputs
        Oscillator props ->
            let
                -- phaseOffsetInput = props.inputs.phaseOffsetInput (just ignore this one for now)

--                 frequencyInputNode = getInputNode graph frequencyInput
                    -- this should be abstracted into a func that just gets the value and updates the graph at the same time (regardless of input type etc)
--                 _ = Debug.log "------------------------" True
                (graph2, frequencyValue) = updateGraphNode' graph externalState props.inputs.frequency
                (graph3, frequencyOffsetValue) = updateGraphNode' graph2 externalState props.inputs.frequencyOffset
                (graph4, phaseOffsetValue) = updateGraphNode' graph3 externalState props.inputs.phaseOffset
--                 _ = Debug.log "phaseOffsetValue" phaseOffsetValue
                (newValue, newPhase) = props.func frequencyValue frequencyOffsetValue phaseOffsetValue props.state.phase -- this func should start accepting frequency
{-                 _ = Debug.log "newValue" newValue
                _ = Debug.log "newPhase" newPhase -}
                newState = {outputValue = newValue, phase = newPhase}
                newNode = Oscillator { props | state = newState }

{-                 _ = Debug.log "externalState" externalState
                _ = Debug.log "frequencyInputValue" frequencyInputValue
                _ = Debug.log "newValue" newValue -}

            in
                (replaceGraphNode newNode graph4, newValue)

        FeedforwardProcessor props ->
            case getInputNodes node graph of
                Just [inputNode] ->
                    let
                        (newGraph, inputValue) = updateGraphNode graph externalState inputNode
                        newValue = props.func inputValue props.state.prevValues
                        newPrevValues = rotateList props.state.outputValue props.state.prevValues
                        newState = {outputValue = newValue, prevValues = newPrevValues }
                        newNode = FeedforwardProcessor { props | state = newState }
                    in
                        (replaceGraphNode newNode newGraph, newValue)
                Just inputNodes ->
                    Debug.crash("multiple inputs not supported yet")
                Nothing ->
                    Debug.crash("no input nodes!")

        Destination props ->
            case getInputNodes node graph of
                Just [inputNode] ->
                    let
                        (newGraph, inputValue) = updateGraphNode graph externalState inputNode
                        newState = { outputValue = inputValue }
                        newNode =  Destination { props | state = newState }
                    in
                        (replaceGraphNode newNode newGraph, inputValue)
                Just inputNodes ->
                    Debug.crash("multiple inputs not supported yet")
                Nothing ->
                    Debug.crash("no input nodes!")

        Add props ->
            let
                updateFunc input (graph, accValue) =
                    let
                        (newGraph, inputValue) = updateGraphNode' graph externalState input
                    in
                        (replaceGraphNode newNode newGraph, accValue + inputValue)

                (newGraph, newValue) = List.foldl updateFunc (graph, 0) props.inputs
                newState = { outputValue = newValue }
                newNode = Add { props | state = newState }
            in
                (replaceGraphNode newNode newGraph, newValue)

        Gain props ->
            let
                -- phaseOffsetInput = props.inputs.phaseOffsetInput (just ignore this one for now)

--                 frequencyInputNode = getInputNode graph frequencyInput
                    -- this should be abstracted into a func that just gets the value and updates the graph at the same externalState (regardless of input type etc)
--                 _ = Debug.log "------------------------" True
                (graph2, signalValue) = updateGraphNode' graph externalState props.inputs.signal
                (graph3, gainValue) = updateGraphNode' graph2 externalState props.inputs.gain
--                 _ = Debug.log "phaseOffsetValue" phaseOffsetValue
                newValue = props.func signalValue gainValue -- this func should start accepting frequency
{-                 _ = Debug.log "newValue" newValue
                _ = Debug.log "newPhase" newPhase -}
                newState = {outputValue = newValue}
                newNode = Gain { props | state = newState }

{-                 _ = Debug.log "externalState" externalState
                _ = Debug.log "frequencyInputValue" frequencyInputValue
                _ = Debug.log "newValue" newValue -}

            in
                (replaceGraphNode newNode graph3, newValue)

--         externalinput props ->
--             let
--                 -- here we get the value from the inputstatedict, using props.input
--                 (graph2, signalvalue) = updategraphnode' graph externalState props.input
--                 (graph3, gainvalue) = updategraphnode' graph2 externalState props.inputs.gain
-- --                 _ = debug.log "phaseoffsetvalue" phaseoffsetvalue
--                 newvalue = props.func signalvalue gainvalue -- this func should start accepting frequency
-- {-                 _ = debug.log "newvalue" newvalue
--                 _ = debug.log "newphase" newphase -}
--                 newstate = {outputvalue = newvalue}
--                 newnode = gain { props | state = newstate }
--
-- {-                 _ = debug.log "externalState" externalState
--                 _ = debug.log "frequencyinputvalue" frequencyinputvalue
--                 _ = debug.log "newvalue" newvalue -}
--
--             in
--                 (replacegraphnode newnode graph3, newvalue)
        Multiply _ -> Debug.crash("Multiply not supported yet")

getInputNode : DictGraph -> String -> AudioNode
getInputNode graph id =
    case (Dict.get id graph) of
        Just node -> node
        Nothing -> Debug.crash("Can't find node: " ++ (toString id))

getInputNode' : DictGraph -> Input -> AudioNode
getInputNode' graph input =
    case input of
        ID id ->
            getInputNode graph id
        Value _ ->
            Debug.crash("see getInputNodes")
        Default ->
            Debug.crash("see getInputNodes")
        GUI _ ->
            Debug.crash("see getInputNodes")
        Node _ ->
            Debug.crash("see getInputNodes")




getInputNodes : AudioNode -> DictGraph -> Maybe (List AudioNode)
getInputNodes node graph =
    let
        getInputNodes' : List Input -> List AudioNode
        getInputNodes' inputs =
            List.map (getInputNode' graph)  inputs
    in
        case node of
            FeedforwardProcessor props ->
                Just [getInputNode' graph props.input]
            Destination props ->
                Just [getInputNode' graph props.input]
            _ ->
                Nothing


-- let's just do this inline


{- updateNodeState : AudioNode -> Float -> AudioNode
updateNodeState node newValue =
    case node of
        Oscillator props ->
            let
                oldState = props.state
                newState = { oldState | outputValue = newValue }
            in
                Oscillator  { props | state = newState }

        Add props ->
            let
                oldState = props.state
                newState = { oldState | outputValue = newValue }
            in
                Add { props | state = newState }

        FeedforwardProcessor props ->
            let
                oldState = props.state
                newPrevValues = rotateList props.state.outputValue props.state.prevValues
                newState =
                    { oldState |
                      outputValue = newValue
                    , prevValues = newPrevValues
                    }
--                 _ = Debug.log "newState" newState
            in
                FeedforwardProcessor { props | state = newState }

        Destination props ->
            let
                oldState = props.state
                newState = { oldState | outputValue = newValue }
            in
                Destination { props | state = newState } -}


toDict : ListGraph -> DictGraph
toDict listGraph =
    let
        createTuple node =
            case node of
                Destination props ->
                    (props.id, node)
                Oscillator props ->
                    (props.id, node)
                FeedforwardProcessor props ->
                    (props.id, node)
                Add props ->
                    (props.id, node)
                Gain props ->
                    (props.id, node)
                Multiply _ ->
                    Debug.crash "Multiply not supported"
        tuples = List.map createTuple listGraph
    in
        Dict.fromList tuples


getDestinationNode : DictGraph -> AudioNode
getDestinationNode graph =
    let
        nodes = Dict.values graph
        isDestinationNode node =
            case node of
                Destination _ ->
                    True
                _ ->
                    False
        destinationNodes = List.filter isDestinationNode nodes
    in
        case List.head destinationNodes of
            Just node
                -> node
            _
                -> Debug.crash("There aren't any nodes of type Destination!")


replaceGraphNode : AudioNode -> DictGraph -> DictGraph
replaceGraphNode node graph =
    Dict.insert (getNodeId node) node graph


getNodeId : AudioNode -> String
getNodeId node =
    case node of
        Destination props -> props.id
        Oscillator props -> props.id
        FeedforwardProcessor props -> props.id
        Add props -> props.id
        Gain props -> props.id
        Multiply _ -> Debug.crash "Multiply not supported"



-- rotateArray : Array -> Array

--------------------------------------------------------------------------------
-- TESTS
--------------------------------------------------------------------------------

-- A

squareA : AudioNode
squareA =
    Oscillator
        { id = "squareA"
        , func = sinWave
        , inputs = { frequency = Value 440.0, phaseOffset = Default, frequencyOffset = Default }
        , state =
            { outputValue = 0.0, phase = 0.0  }
        }

destinationA : AudioNode
destinationA =
    Destination
        { id = "destinationA"
        , input = ID "squareA"
        , state =
            { outputValue = 0.0 }
        }

squareAT1 : AudioNode
squareAT1 =
    Oscillator
        { id = "squareA"
        , inputs = { frequency = Value 440.0, phaseOffset = Default, frequencyOffset = Default }
        , func = sinWave
        , state =
            { outputValue = 1.0, phase = 0.0  }
        }

destinationAT1 : AudioNode
destinationAT1 =
    Destination
        { id = "destinationA"
        , input = ID "squareA"
        , state =
            { outputValue = 1.0 }
        }

testGraph : ListGraph
testGraph =
    [ squareA
    , destinationA
    ]

testDictGraph : DictGraph
testDictGraph = toDict testGraph

-- B

{- squareB =
    Oscillator
        { id = "squareB"
        , func = sinWave
        , inputs = [Value 440.0, Default]
        , state =
            { outputValue = 0.0  }
        }


lowpassB =
    FeedforwardProcessor
        { id = "lowpassB"
        , input = ID "squareB"
        , func = simpleLowPassFilter
        , state =
            { outputValue = 0.0
            , prevValues = [0.0, 0.0, 0.0]
            }
        }

destinationB =
    Destination
        { id = "destinationB"
        , input = ID "lowpassB"
        , state =
            { outputValue = 0.0 }
        }

{- squareAT1 =
    Oscillator
        { id = "squareA"
        , func = squareWave
        , state =
            { outputValue = Just 1.0  }
        }

destinationAT1 =
    Destination
        { id = "destinationA"
        , input = ID "squareA"
        , state =
            { outputValue = Just 1.0 }
        } -}

testGraphB : ListGraph
testGraphB =
    [ squareB
    , lowpassB
    , destinationB
    ]

testDictGraphB = toDict testGraphB -}




feetless : List a -> List a
feetless list =
    List.take ((List.length list) - 1) list


rotateList : a -> List a -> List a
rotateList value list  =
  [value] ++ feetless list

tests : Test
tests =
    suite "A Test Suite"
        [
{-           test "getInputNodes"
            (assertEqual
                (Just [squareA])
                (getInputNodes  destinationA testDictGraph)
            )
        , test "getInputNodes"
            (assertEqual
                Nothing
                (getInputNodes squareA testDictGraph)
            )
        , test "getNextSample"
            (assertEqual
                (toDict [squareAT1, destinationAT1], 1.0)
                (updateGraph testDictGraph 0.0)
            ) -}
          test "rotateList"
            (assertEqual
                [4, 3, 2]
                (rotateList 4 [3, 2, 1])
            )
{-         , test "getNextSample"
            (assertEqual
                (toDict [squareAT1, destinationAT1], 1.0)
                (updateGraph testDictGraphB 0.0)
            ) -}
        ]


{- (Dict.fromList
    [ ("destination", Destination
        { id = "destination"
        , input = ID "square1"
        , state = { outputValue = Nothing }
        }
       )
    , ( "square1", Generator
        { id = "square1",
        , $func = <func>,
        , state = { outputValue = Just -1 }
        }
        )
    ]
    , -1
) -}
-- main : Graphics.Element.Element
-- main =
--     elementRunner tests