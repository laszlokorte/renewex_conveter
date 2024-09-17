# RenewEx Converter

![RenewEx](./guides/images/logo.png)

[Renew](http://renew.de/) file converter to turn files parsed with [RenewEx](https://hexdocs.pm/renewex/) ([Repository](https://github.com/laszlokorte/renewex/)) into a canonical structure that can be worked with more easily (for example be imported into a database). 

[![Hex.pm](https://img.shields.io/hexpm/v/renewex_converter.svg)](https://hex.pm/packages/renewex_converter) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/renewex_converter/)

---

## Test cases

The conveter is tested [on more than 1000 example files.](./test/fixtures/valid_files)

### Running tests

All test:
```sh
mix test
```

Only fast tests:
```sh
mix test --exclude slow
```
