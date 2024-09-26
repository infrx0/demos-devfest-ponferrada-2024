apt update && sudo apt upgrade -y
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
apt install -y golang cmake python3 nodejs
snap install aws-cli --classic
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
cargo install wasm-pack

git clone https://github.com/infrx0/demos-devfest-ponferrada-2024.git
cd demos-devfest-ponferrada-2024

#Compilar Rust
wasm-pack build --target web
aws s3 cp main.html s3://demo-devfest-ponferrada-2024/rust/
aws s3 cp pkg/wasm_particles.js s3://demo-devfest-ponferrada-2024/rust/pkg/
aws s3 cp  pkg/wasm_particles_bg.wasm s3://demo-devfest-ponferrada-2024/rust/pkg/

#Compilar C
emcc particles.c -o particles.js -s WASM=1 -s EXPORTED_FUNCTIONS="['_main_loop', '_init_system']" -s EXPORTED_RUNTIME_METHODS="['ccall', 'cwrap']"
aws s3 cp main.html s3://demo-devfest-ponferrada-2024/c/
aws s3 cp particles.js s3://demo-devfest-ponferrada-2024/c/
aws s3 cp particles.wasm s3://demo-devfest-ponferrada-2024/c/

#Compilar Golang
go mod init go_wasm
go mod tidy
GOOS=js GOARCH=wasm go build -o main.wasm
cp $(go env GOROOT)/misc/wasm/wasm_exec.js .
aws s3 cp main.html s3://demo-devfest-ponferrada-2024/go/
aws s3 cp main.wasm s3://demo-devfest-ponferrada-2024/go/
aws s3 cp wasm_exec.js s3://demo-devfest-ponferrada-2024/go/
