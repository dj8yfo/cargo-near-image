# `sourcescan/cargo-near` Docker Image

## Overview

Hook local development `cargo-near` folder into the checkout folder of this repo (`cargo-near` is git-ignored): 

```bash
ln -s $local_fs_cargo_near cargo-near
```

See [Justfile](./Justfile)
