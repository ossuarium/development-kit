# development-kit ChangeLog

## 0.0.1-alpha

### Implemented

- Populating working environment from git repo.
- Flexible asset pipeline with sprockets.
  * `Kit::Bit::Assets` class can be used standalone.
  * Environment automatically compiles assets referenced in source files.

### In progress or planned

- Support for auto-generation of responsive images
- More environment interaction
  * Go from an arbitrary directory structure to the deployment structure
- Site actions
  * deploy
  * clone for testing or development
