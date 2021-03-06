module SelectableItemList exposing
    ( SelectableItemList
    , empty, singleton, fromList
    , select, unselect
    , selected
    , map, indexedMap
    , toList, flatten, length
    )

{-|


# SelectableItemList

Sometimes, one might want to have a list of elements where exactly one item at most might be
selected, and the selected item might be have a different type than the original list. This is where
`SelectableItemList` comes in handy.


## Creation

@docs SelectableItemList
@docs empty, singleton, fromList


## Selections

@docs select, unselect
@docs selected


## Transformations

@docs map, indexedMap
@docs toList, flatten, length

-}

import Maybe.Extra


{-| An opaque type describing a `SelectableItemList`.
-}
type SelectableItemList a b
    = SelectableItemList (List a) (Maybe b) (List a)


{-| Builds an empty selectable item list with Nothing selected
-}
empty : SelectableItemList a b
empty =
    SelectableItemList [] Nothing []


{-| Builds a selectable ite, list with just one element that is selected
-}
singleton : b -> SelectableItemList a b
singleton item =
    SelectableItemList [] (Just item) []


{-| Builds a selectable item list from an existing list with no selected element
-}
fromList : List a -> SelectableItemList a b
fromList existing =
    SelectableItemList existing Nothing []


{-| Maps both the contents of a selectable item list and the selected element given two transformation functions
-}
map : (a -> c) -> (b -> d) -> SelectableItemList a b -> SelectableItemList c d
map f g (SelectableItemList start selectable end) =
    SelectableItemList
        (List.map f start)
        (Maybe.map g selectable)
        (List.map f end)


indexedMap : (Int -> a -> c) -> (Int -> b -> d) -> SelectableItemList a b -> SelectableItemList c d
indexedMap f g (SelectableItemList start selectable end) =
    let
        indexedStart : List c
        indexedStart =
            List.indexedMap f start

        indexedSelectable : Maybe d
        indexedSelectable =
            Maybe.map (\v -> g (List.length start) v) selectable

        untilEnd : Int
        untilEnd =
            Maybe.map (always 1) selectable
                |> Maybe.withDefault 0
                |> (+) (List.length start)

        indexedEnd : List c
        indexedEnd =
            List.indexedMap (\index value -> f (index + untilEnd) value) end
    in
    SelectableItemList indexedStart indexedSelectable indexedEnd


{-| Returns the selected element if it exists
-}
selected : SelectableItemList a b -> Maybe b
selected (SelectableItemList _ selectable _) =
    selectable


{-| Selects an element of the selectable item list by transforming it into the selected type,
and de-transforming a potentially pre-selected element and adding back to the rest of the list
-}
select : (b -> a) -> (a -> b) -> Int -> SelectableItemList a b -> SelectableItemList a b
select g f index list =
    let
        contents =
            toList identity g list

        start =
            List.take index contents

        selectable =
            List.drop index contents
                |> List.head
                |> Maybe.map f

        end =
            List.drop (index + 1) contents
    in
    SelectableItemList start selectable end


{-| Un-selects the current item (if set) from the `SelectableItemList`.
-}
unselect : (b -> a) -> SelectableItemList a b -> SelectableItemList a b
unselect f (SelectableItemList start selectable end) =
    SelectableItemList start Nothing (Maybe.Extra.cons (Maybe.map f selectable) end)


{-| Converts the `SelectableItemList` into a homogeneous `List` data structure.
-}
toList : (a -> c) -> (b -> c) -> SelectableItemList a b -> List c
toList f g (SelectableItemList start selectable end) =
    List.map f end
        |> Maybe.Extra.cons (Maybe.map g selectable)
        |> List.append (List.map f start)


{-| Flattens the selectable item list into a list if the selected element is of the same type as the non-selected ones
-}
flatten : SelectableItemList a a -> List a
flatten =
    toList identity identity


{-| Computes the length of the selectable item list
-}
length : SelectableItemList a b -> Int
length list =
    toList (always ()) (always ()) list
        |> List.length
