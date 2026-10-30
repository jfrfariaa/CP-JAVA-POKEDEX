# Pokédex API

Projeto da disciplina de **Domain Driven Design (Java)** da FIAP: uma API REST para registrar os pokémons capturados, com front-end próprio e persistência no Oracle da FIAP.

> **Jefferson Faria de Oliveira** · RM 573038

---

## Sumário

- [Tecnologias](#tecnologias)
- [Arquitetura](#arquitetura)
- [Endpoints](#endpoints)
- [Atualização (PUT)](#atualização-put)
- [Como executar](#como-executar)
- [Testando no Insomnia](#testando-no-insomnia)
- [Front-end](#front-end)

## Tecnologias

| | |
|---|---|
| Linguagem | Java 21 |
| Framework | Spring Boot 4.1.1 (Web MVC + Bean Validation) |
| Banco de dados | Oracle (`oracle.fiap.com.br`) via JDBC puro |
| Build | Maven (com Maven Wrapper — não precisa instalar o Maven) |
| Testes de requisição | Insomnia |

## Arquitetura

Cada camada tem uma única responsabilidade e conversa só com a camada vizinha:

| Pacote | Classe | Papel |
|---|---|---|
| `resource` | `PokemonResource` | Recebe as requisições HTTP e devolve `ResponseEntity` com o status code |
| `bo` | `PokemonBO` | Regras de negócio (ex.: data da captura não pode estar no futuro) |
| `dao` | `PokemonDAO` | SQL com `PreparedStatement` na tabela `DDD_POKEMONS` |
| `dao` | `ConnectionFactory` | Conexão única com o Oracle (Factory + Singleton), lida de variáveis de ambiente |
| `to` | `PokemonTO` | Objeto que carrega os dados entre as camadas, com as anotações de validação |
| `exception` | `ValidationHandler` | Transforma erros de validação em respostas 400 com a mensagem de cada campo |
| `resource` | `CorsFilter` | Libera o CORS para front-ends em outro domínio |

Fluxo de uma requisição:

```
Cliente (Insomnia / front-end)
   │  JSON
   ▼
PokemonResource ──► PokemonBO ──► PokemonDAO ──► Oracle
                  (PokemonTO circula entre as camadas)
```

## Endpoints

Base: `http://localhost:8080/pokedex`

| Verbo | Rota | O que faz | Resposta de sucesso | Resposta de erro |
|---|---|---|---|---|
| `GET` | `/pokedex` | Lista todos os pokémons | `200` | `404` |
| `GET` | `/pokedex/{codigo}` | Busca um pokémon pelo código | `200` | `404` |
| `POST` | `/pokedex` | Cadastra um pokémon | `201` | `400` |
| `PUT` | `/pokedex/{codigo}` | Atualiza um pokémon | `201` | `400` |
| `DELETE` | `/pokedex/{codigo}` | Remove um pokémon | `204` | `404` |

Campos do JSON e validações:

| Campo | Tipo | Regras |
|---|---|---|
| `nome` | texto | obrigatório, até 100 caracteres |
| `tipo` | texto | obrigatório, até 50 caracteres |
| `nivel` | inteiro | obrigatório, de 1 a 100 |
| `peso` | decimal | obrigatório, maior que zero |
| `dataDaCaptura` | data `aaaa-mm-dd` | obrigatória, não pode ser no futuro |

## Atualização (PUT)

A funcionalidade de atualização passa pelas três camadas:

1. **`PokemonResource.update()`** — mapeado com `@PutMapping("/{codigo}")`. Recebe o código pela URL (`@PathVariable`) e o JSON pelo corpo (`@RequestBody @Valid`), coloca o código no objeto e chama o BO.
2. **`PokemonBO.update()`** — aplica a mesma regra de negócio do cadastro (a data da captura não pode ser no futuro) e chama o DAO.
3. **`PokemonDAO.update()`** — executa `UPDATE ddd_pokemons SET ... WHERE codigo = ?`. Se nenhuma linha for alterada (código inexistente), devolve `null` e a API responde `400`.

O JSON usado para testar está em [`insomnia/atualizacao.txt`](insomnia/atualizacao.txt):

```json
{
  "nome": "Wartortle",
  "tipo": "Água",
  "nivel": 32,
  "peso": 22.5,
  "dataDaCaptura": "2025-08-02"
}
```

`PUT /pokedex/3` com esse corpo → `201 Created`, devolvendo o pokémon já atualizado.

## Como executar

**Pré-requisitos:** JDK 21 e um usuário no Oracle da FIAP.

1. **Crie a tabela** — no SQL Developer, conectado com o seu RM, execute o [`script.sql`](script.sql). Ele cria a `DDD_POKEMONS` e cadastra três pokémons de exemplo.

2. **Suba a API** — no PowerShell, dentro da pasta do projeto:

   ```powershell
   .\rodar-local.ps1
   ```

   O script pede o usuário e a senha do Oracle, guarda só na sessão do terminal (nenhuma senha vai para o código ou para o GitHub) e roda o projeto pelo Maven Wrapper.

   Pelo IntelliJ também funciona: em **Run → Edit Configurations → Environment variables**, defina `DB_USER=seu_rm;DB_PASSWORD=sua_senha` e rode a classe `PokedexApplication`.

3. **Acesse** `http://localhost:8080/` (front-end) ou `http://localhost:8080/pokedex` (JSON).

Variáveis de ambiente aceitas:

| Variável | Obrigatória | Padrão |
|---|---|---|
| `DB_USER` | sim | — |
| `DB_PASSWORD` | sim | — |
| `DB_URL` | não | `jdbc:oracle:thin:@oracle.fiap.com.br:1521:ORCL` |
| `PORT` | não | `8080` |

Para gerar o `.jar`: `.\mvnw.cmd clean package` → `target/pokedex.jar`. Também há um `Dockerfile` para rodar em contêiner.

## Testando no Insomnia

1. Importe [`insomnia/insomnia-pokedex.json`](insomnia/insomnia-pokedex.json) (**Import → From File**).
2. Selecione o ambiente **Local**.
3. A coleção já tem uma requisição para cada endpoint, incluindo o **update (PUT)** e um **save inválido** que mostra as mensagens do Bean Validation.

Os corpos das requisições também estão em arquivos `.txt` na pasta [`insomnia/`](insomnia/): `cadastro.txt`, `atualizacao.txt` e `invalido.txt`.

## Front-end

O arquivo [`src/main/resources/static/index.html`](src/main/resources/static/index.html) é servido pelo próprio Spring em `http://localhost:8080/`. Feito em HTML, CSS e JavaScript puros, ele:

- lista os pokémons em cards coloridos pelo tipo, com busca por nome ou tipo;
- cadastra (`POST`) e **edita (`PUT`)** pelo mesmo formulário;
- exclui (`DELETE`) com confirmação;
- mostra embaixo de cada campo as mensagens de validação que a API devolve;
- tem modo escuro automático e se adapta ao celular.
