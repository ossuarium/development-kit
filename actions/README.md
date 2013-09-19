# Actions

Actions are modules that add instance methods to `Kit::Bit` objects.
Bits can be grouped together. To create a new group, run

````bash
$ rake add:group[new_group_name]
````

in the kit's root directory.

This will create a new group in the database and an action file named `new_group_name.rb`.

Any instance methods added to the `KitActionsNewGroupName` module can be called on a `Bit` object which belongs to that group.
The `KitActionsDefault` module is loaded for all bits.

If you want to use additional helper files instead of putting all of the behavior in `new_group_name.rb`, just place them in `actions/new_group_name`.
You will still need to include any Ruby files you create here in `new_group_name.rb`.
