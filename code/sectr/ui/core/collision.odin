package sectr

UI_SpacialIndexingMethod :: enum(i32) {
	QuadTree,
	SpacialHash,
}

ui_collision_register :: proc( box : ^UI_Box )
{

}

ui_collision_query :: proc ( box : ^UI_Box ) -> DLL_NodePN(UI_Box) {
	return {}
}

QuadTree_Tile :: struct {

}

QuadTree :: struct
{
	boundary : Range2,
	
}

SpacialHashMap :: struct {
	
}