<?php 

class Constants 
{ 
  // Server info
  const SERVER_NAME = "localhost";
  const USER_NAME = "iosrecip";
  CONST PASSWORD = "Wannabefoodi3$";

  // Table names
  const RECIPES_DATABASE = "iosrecip_recipes"; 
  const RECIPES_TABLE =  "iosrecip_recipes.recipes";
  const RECIPE_INGREDIENTS_TABLE = "iosrecip_recipes.recipe_ingredients";
  const RECIPE_INSTRUCTIONS_TABLE = "iosrecip_recipes.recipe_instructions";
  
  const IMAGES_TABLE = "iosrecip_recipes.images";
  const IMAGE_BLOBS_TABLE = "iosrecip_recipes.image_blobs";

  // Misc
  const SUCCESS_STRING = '{"result" : "success"}';
  const ERROR_STRING = '{"result" : "error"}';
  
} 

?> 

