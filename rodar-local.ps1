# Roda a Pokedex API localmente (http://localhost:8080/pokedex)
# Pede o usuario (RM) e a senha do Oracle da FIAP se as variaveis DB_USER / DB_PASSWORD nao existirem.
# As credenciais ficam so na sessao do terminal: nada e salvo em arquivo.

if (-not $env:DB_USER) {
    $env:DB_USER = Read-Host "Usuario do Oracle (ex: rm123456)"
}
if (-not $env:DB_PASSWORD) {
    $senha = Read-Host "Senha do Oracle" -AsSecureString
    $env:DB_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($senha))
}

& "$PSScriptRoot\mvnw.cmd" spring-boot:run
