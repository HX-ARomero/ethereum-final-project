# Token Farm Project

## Autor
> Ariel Alejandro Romero

## Descripción

> Este proyecto implementa una granja de tokens ("Token Farm") que permite a los usuarios hacer staking de sus tokens LP (Liquidity Provider) para recibir recompensas en tokens DApp. Las recompensas se distribuyen proporcionalmente al total stakeado, y el contrato incluye funcionalidades adicionales como la reclamación de recompensas y el retiro de los tokens LP.

El proyecto utiliza contratos inteligentes desarrollados en Solidity y aprovecha las librerías de OpenZeppelin para asegurar la seguridad y estandarización del código.

## Características principales

- Staking de tokens LP: Los usuarios pueden depositar tokens LP para participar en el sistema de staking.
- Distribución de recompensas: Las recompensas se distribuyen proporcionalmente al porcentaje de tokens LP que cada usuario tiene en staking.
- Reclamación de recompensas: Los usuarios pueden reclamar sus recompensas acumuladas en tokens DApp.
- Retiro de tokens LP: Los usuarios pueden retirar sus tokens LP en cualquier momento.
- Gestor del contrato: Solo el propietario del contrato tiene acceso a ciertas funcionalidades administrativas, como distribuir recompensas globales.

## Contratos

1. TokenFarm.sol
  - Este contrato gestiona la lógica de staking y distribución de recompensas.
  - Variables clave:
    - totalStakingBalance: Suma total de tokens LP en staking.
    - REWARD_PER_BLOCK: Cantidad de recompensas generadas por bloque.
    - stakers: Lista de todas las direcciones que han hecho staking.
    - stakingBalance, pendingRewards, checkpoints: Mapeos para gestionar balances y recompensas individuales.
  - Funciones principales:
    - deposit(uint256 _amount): Permite a los usuarios hacer staking de tokens LP.
    - withdraw(): Retira todos los tokens LP en staking.
    - claimRewards(): Reclama las recompensas acumuladas.
    - distributeRewardsAll(): Distribuye recompensas a todos los stakers (solo el propietario puede ejecutarla).
2. DAppToken.sol
  - Este contrato implementa el token DApp, que se usa como recompensa en la granja de tokens.
  - Implementa el estándar ERC20.
  - Incluye la función mint para que el propietario pueda generar nuevos tokens.
3. LPToken.sol
  - Contrato ERC20 simple que representa los tokens LP (Liquidity Provider) necesarios para participar en el sistema de staking.

## Requisitos
- Node.js
- Hardhat
- OpenZeppelin Contracts
- Una red blockchain compatible con EVM (como Ethereum o redes de prueba como Sepolia o Goerli).

## Instalación

1. Clona el repositorio:
```shell
git clone <URL-del-repositorio>
cd <nombre-del-repositorio>
```

2. Instala las dependencias:
```shell
npm install
```

3. Compila los contratos:
```shell
npx hardhat compile
```

4. Despliegue
```shell
# Levantamos un nodo local:
npx hardhat node

# Corremos el archivo que deploya los tres contratos en el nodo local:
npx hardhat run scripts/deploy.ts --network localhost
```

## Uso

Hacer staking:
- Llama a la función deposit en el contrato TokenFarm con la cantidad de tokens LP a stakear.

Retirar tokens LP:
- Llama a la función withdraw en el contrato TokenFarm.

Reclamar recompensas:
- Llama a la función claimRewards en el contrato TokenFarm.

Distribuir recompensas globales (solo el propietario):
- Llama a la función distributeRewardsAll en el contrato TokenFarm.

## Scripts disponibles
- deploy.js: Despliega los contratos en la red especificada.
- interact.js: Contiene ejemplos para interactuar con los contratos desplegados.
- Tests: Escribe y ejecuta los tests utilizando Hardhat
```shell
npx hardhat test
```

## Consideraciones
- El contrato usa OpenZeppelin para garantizar la seguridad de los estándares ERC20.
- Revisa las tarifas de gas al desplegar los contratos en una red principal.

## Licencia
- Este proyecto está bajo la licencia MIT. Consulta el archivo LICENSE para más información.