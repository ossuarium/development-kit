# Migrations

Manage your kit's database structure using [Active Record Migrations](http://api.rubyonrails.org/classes/ActiveRecord/Migration.html).
To generate a new migration, run

````bash
$ rake mk:migration[new_migration_name]
````

in the kit's root directory.
This will create a new migration file named `YYYYMMDDHHMMSS_new_migration_name.rb`.
Every new kit starts with the migration `CreateBasicTables` and possibly others as features are added and kit evolves.

Run

````bash
$ rake db:migrate
````

in the kit's root directory to migrate your kit's database to the latest version.
