# Write the Chapter 2 Kronecker JAGS model

`write_model_ch2_kron()` emits a JAGS model file that places a Kronecker
precision \\T = T_B \otimes T_P\\ over stacked per-biomarker parameters
(5 per biomarker).

Expected data in the JAGS environment includes:

- scalar: `n_blocks`, `nsubj`, `n_params` (should be 5)

- hypermeans: `mu.hyp[b, ]`, hyper-precisions: `prec.hyp[b, , ]`

- Wishart pieces: `OmegaP[5,5]`, `nuP`, `OmegaB[n_blocks,n_blocks]`,
  `nuB`

- measurement: `smpl.t`, `nsmpl`, `prec.logy.hyp`

## Usage

``` r
write_model_ch2_kron(path = "model_ch2_kron.jags")
```

## Arguments

- path:

  File path to write (default `"model_ch2_kron.jags"`).

## Value

Invisibly returns `path`.

## Author

Kwan Ho Lee

## Examples

``` r
# Write the model to a temp file and confirm it exists
p <- write_model_ch2_kron(file.path(tempdir(), "model_ch2_kron.jags"))
print(file.exists(p))
#> [1] TRUE
```
