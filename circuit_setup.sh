#!/bin/bash

# 1. Start a new powers of tau ceremony
echo "Starting a new powers of tau ceremony..."
snarkjs powersoftau new bn128 14 pot14_0000.ptau -v

# 2. Contribute to the ceremony
echo "Contributing to the ceremony (First contribution)..."
snarkjs powersoftau contribute pot14_0000.ptau pot14_0001.ptau --name="First contribution" -v

# 3. Provide a second contribution
echo "Contributing to the ceremony (Second contribution)..."
snarkjs powersoftau contribute pot14_0001.ptau pot14_0002.ptau --name="Second contribution" -v -e="some random text"

# 4. Provide a third contribution using third party software
echo "Providing a third contribution using third party software..."
snarkjs powersoftau export challenge pot14_0002.ptau challenge_0003
snarkjs powersoftau challenge contribute bn128 challenge_0003 response_0003 -e="some random text"
snarkjs powersoftau import response pot14_0002.ptau response_0003 pot14_0003.ptau -n="Third contribution name"

# 5. Verify the protocol so far
echo "Verifying the protocol so far..."
snarkjs powersoftau verify pot14_0003.ptau

# 6. Apply a random beacon
echo "Applying a random beacon..."
snarkjs powersoftau beacon pot14_0003.ptau pot14_beacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon"

# 7. Prepare phase 2
echo "Preparing phase 2..."
snarkjs powersoftau prepare phase2 pot14_beacon.ptau pot14_final.ptau -v

# 8. Compile the circuit
echo "Compiling the circuit..."
circom circuit.circom --r1cs --wasm --sym

# 9. View information about the circuit
echo "Viewing information about the circuit..."
snarkjs r1cs info circuit.r1cs

# 10. Print the constraints
echo "Printing the constraints..."
snarkjs r1cs print circuit.r1cs circuit.sym

# 11. Export r1cs to json
echo "Exporting r1cs to json format..."
snarkjs r1cs export json circuit.r1cs circuit.r1cs.json
cat circuit.r1cs.json

# 12. Calculate the witness
echo "Creating input file for the circuit..."
cat <<EOT > input.json
{"a": 3, "b": 11}
EOT

echo "Calculating the witness..."
cd circuit_js
node generate_witness.js circuit.wasm ../input.json ../witness.wtns
cd ..

echo "Checking if the generated witness complies with the r1cs file..."
snarkjs wtns check circuit.r1cs witness.wtns

# 13. Setup
echo "Setting up (Groth16)..."
snarkjs groth16 setup circuit.r1cs pot14_final.ptau circuit_0000.zkey

# 14. Contribute to the phase 2 ceremony
echo "Contributing to the phase 2 ceremony (First contribution)..."
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -v

# 15. Provide a second contribution
echo "Contributing to the phase 2 ceremony (Second contribution)..."
snarkjs zkey contribute circuit_0001.zkey circuit_0002.zkey --name="Second contribution Name" -v -e="Another random entropy"

# 16. Provide a third contribution using third party software
echo "Providing a third contribution using third party software..."
snarkjs zkey export bellman circuit_0002.zkey challenge_phase2_0003
snarkjs zkey bellman contribute bn128 challenge_phase2_0003 response_phase2_0003 -e="some random text"
snarkjs zkey import bellman circuit_0002.zkey response_phase2_0003 circuit_0003.zkey -n="Third contribution name"

# 17. Verify the latest zkey
echo "Verifying the latest zkey..."
snarkjs zkey verify circuit.r1cs pot14_final.ptau circuit_0003.zkey

# 18. Apply a random beacon
echo "Applying a random beacon..."
snarkjs zkey beacon circuit_0003.zkey circuit_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"

# 19. Verify the final zkey
echo "Verifying the final zkey..."
snarkjs zkey verify circuit.r1cs pot14_final.ptau circuit_final.zkey

# 20. Export the verification key
echo "Exporting the verification key..."
snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

# 21. Create the proof
echo "Creating the proof (Groth16)..."
snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json

# 22. Verify the proof
echo "Verifying the proof (Groth16)..."
snarkjs groth16 verify verification_key.json public.json proof.json

echo "Setup and proof generation complete."

