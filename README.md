# ComputerCraftExe
Various scripts for ComputerCraft 1.75

## Maker
Allows to make recipes on computers and turtles.

Requirements:
 * STD
 * Forms
 * STDTurtle (optional)

Usage:
`maker [-h] recipe`
 * `-h`: Show help
 * `recipe`: Recipe path

 
## Craft
Automatically craft items using recipes made with Maker.

Requirements:
 * STD
 * STDTurtle

Usage:
`craft recipeFolder finalRecipe amount [-t] [-s]`
 * `recipeFolder`: Folder path that contains all the recipes
 * `finalRecipe`: Recipe file (not path) contained in the recipe folder that will be crafted
 * `amount`: How many items to craft
 * `-t`: Only shows requirements combinations
 * `-s`: Scan bottom chest without move items up and down
