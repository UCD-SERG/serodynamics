# Write the model to a temp file and confirm it exists
p <- write_model_ch2_kron(file.path(tempdir(), "model_ch2_kron.jags"))
print(file.exists(p))
