# Models

Models are subclasses of `ActiveRecord::Base`.
To add a new data model to your kit run

````bash
$ rake mk:model[new_model_name]
````

in the kit's root directory (`new_model_name` should be a singular noun).
This will create a new model file named `new_model_name.rb`.

All kits start with the basic models `Bit`, `Group`, `User`, and `Permission`, but you can still create those model files here to add custom functionality to the basic models.
