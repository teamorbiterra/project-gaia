extends Node



var active_confined_menu: ConfinedMenu=null
var active_neo_designation:String=""

enum requests{
REMOVE_AND_ADD,
ADD_PARALLEL,
QUIT_GAME,
SAVE_GAME,
LOAD_GAME_STATE
}
