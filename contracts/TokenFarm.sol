/**
 * SPDX-License-Identifier: MIT
 * @title Proportional Token Farm
 * @notice Una granja de staking donde las recompensas se distribuyen proporcionalmente al total stakeado.
 */
pragma solidity ^0.8.18;

import "./DappToken.sol";
import "./LPToken.sol";

contract TokenFarm {
    // Variables de estado
    string public name = "Proportional Token Farm";
    address public owner;
    DappToken public dappToken;
    LPToken public lpToken;

    uint256 public constant REWARD_PER_BLOCK = 1e18; // Recompensa por bloque (total para todos los usuarios)
    uint256 public totalStakingBalance; // Total de tokens en staking

    address[] public stakers;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public checkpoints;
    mapping(address => uint256) public pendingRewards;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    // Eventos
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 totalRewards);

    // Constructor
    constructor(DappToken _dappToken, LPToken _lpToken) {
        dappToken = _dappToken;
        lpToken = _lpToken;
        owner = msg.sender;
    }

    // Modificador para restringir acceso al owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede ejecutar esta funcion");
        _;
    }

    /**
     * @notice Deposita tokens LP para staking.
     * @param _amount Cantidad de tokens LP a depositar.
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "El monto debe ser mayor a 0");

        // Transferir tokens LP del usuario a este contrato.
        lpToken.transferFrom(msg.sender, address(this), _amount);

        // Actualizar el balance de staking del usuario en stakingBalance.
        stakingBalance[msg.sender] += _amount;
        totalStakingBalance += _amount;

        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
            hasStaked[msg.sender] = true;
        }

        isStaking[msg.sender] = true;

        if (checkpoints[msg.sender] == 0) {
            checkpoints[msg.sender] = block.number;
        }

        // Calcular y distribuir recompensas para el usuario actual.
        distributeRewards(msg.sender);
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Retira todos los tokens LP del staking.
     */
    function withdraw() external {
        require(isStaking[msg.sender], "No tienes tokens en staking");
        uint256 balance = stakingBalance[msg.sender];
        require(balance > 0, "Tu balance es 0");

        // Calcular y distribuir las recompensas antes del retiro.
        distributeRewards(msg.sender);

        // Restablecer el balance del usuario en stakingBalance.
        stakingBalance[msg.sender] = 0;
        totalStakingBalance -= balance;
        isStaking[msg.sender] = false;

        // Transferir los tokens LP de vuelta al usuario.
        lpToken.transfer(msg.sender, balance);
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Reclama las recompensas acumuladas.
     */
    function claimRewards() external {
        uint256 pendingAmount = pendingRewards[msg.sender];
        require(pendingAmount > 0, "No tienes recompensas pendientes");

        // Restablecer recompensas pendientes a cero
        pendingRewards[msg.sender] = 0;

        // Transferir tokens de recompensa al usuario
        dappToken.mint(msg.sender, pendingAmount);

        emit RewardsClaimed(msg.sender, pendingAmount);
    }


    /**
     * @notice Distribuye recompensas a todos los stakers.
     * @dev Sólo el owner puede llamar a esta función.
     */
    function distributeRewardsAll() external onlyOwner {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            if (isStaking[staker]) {
                totalRewards += distributeRewards(staker);
            }
        }

        emit RewardsDistributed(totalRewards);
    }

    /**
     * @notice Distribuye recompensas a un usuario específico.
     * @param beneficiary Dirección del usuario que recibirá las recompensas.
     * @return reward Cantidad de recompensa calculada.
     */
    function distributeRewards(address beneficiary) private returns (uint256) {
    uint256 lastCheckpoint = checkpoints[beneficiary];
    if (block.number <= lastCheckpoint || totalStakingBalance == 0) {
        return 0;
    }

    // Calcular la cantidad de bloques transcurridos desde el último checkpoint
    uint256 blocksPassed = block.number - lastCheckpoint;

    // Calcular la participación proporcional del usuario
    uint256 userShare = (stakingBalance[beneficiary] * 1e18) / totalStakingBalance;

    // Calcular la recompensa basada en los bloques pasados y la participación del usuario
    uint256 reward = (REWARD_PER_BLOCK * blocksPassed * userShare) / 1e18;

    // Actualizar las recompensas pendientes y el checkpoint del usuario
    pendingRewards[beneficiary] += reward;
    checkpoints[beneficiary] = block.number;

    return reward;
}
}
