/**
 * SPDX-License-Identifier: MIT
 * @title Proportional Token Farm
 * @notice Una granja de staking donde las recompensas se distribuyen proporcionalmente al total stakeado.
 * @author Ariel Romero
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

    // Estructura para almacenar la información de staking de un usuario
    struct StakingInfo {
        uint256 stakingBalance;
        uint256 checkpoint;
        uint256 pendingRewards;
        bool hasStaked;
        bool isStaking;
    }

    // Reemplazar los mappings por la estructura StakingInfo
    mapping(address => StakingInfo) public stakingInfo;

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

    // Modificadores
    modifier onlyStaking() {
        require(stakingInfo[msg.sender].isStaking, "You are not staking");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this function");
        _;
    }

    /**
     * @notice Deposita tokens LP para staking.
     * @param _amount Cantidad de tokens LP a depositar.
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        // Transferir tokens LP del usuario a este contrato.
        lpToken.transferFrom(msg.sender, address(this), _amount);

        // Actualizar el balance de staking del usuario en stakingInfo.
        stakingInfo[msg.sender].stakingBalance += _amount;
        totalStakingBalance += _amount;

        if (!stakingInfo[msg.sender].hasStaked) {
            stakers.push(msg.sender);
            stakingInfo[msg.sender].hasStaked = true;
        }

        stakingInfo[msg.sender].isStaking = true;

        if (stakingInfo[msg.sender].checkpoint == 0) {
            stakingInfo[msg.sender].checkpoint = block.number;
        }

        // Calcular y distribuir recompensas para el usuario actual.
        distributeRewards(msg.sender);
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice Retira todos los tokens LP del staking.
     */
    function withdraw() external onlyStaking {
        uint256 balance = stakingInfo[msg.sender].stakingBalance;
        require(balance > 0, "Your balance is 0");

        // Calcular y distribuir las recompensas antes del retiro.
        distributeRewards(msg.sender);

        // Restablecer el balance del usuario en stakingInfo.
        stakingInfo[msg.sender].stakingBalance = 0;
        totalStakingBalance -= balance;
        stakingInfo[msg.sender].isStaking = false;

        // Transferir los tokens LP de vuelta al usuario.
        lpToken.transfer(msg.sender, balance);
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Reclama las recompensas acumuladas.
     */
    function claimRewards() external onlyStaking {
        uint256 pendingAmount = stakingInfo[msg.sender].pendingRewards;
        require(pendingAmount > 0, "You have no pending rewards");

        // Restablecer recompensas pendientes a cero
        stakingInfo[msg.sender].pendingRewards = 0;

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
            if (stakingInfo[staker].isStaking) {
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
        uint256 lastCheckpoint = stakingInfo[beneficiary].checkpoint;
        if (block.number <= lastCheckpoint || totalStakingBalance == 0) {
            return 0;
        }

        // Calcular la cantidad de bloques transcurridos desde el último checkpoint
        uint256 blocksPassed = block.number - lastCheckpoint;

        // Calcular la participación proporcional del usuario
        uint256 userShare = (stakingInfo[beneficiary].stakingBalance * 1e18) / totalStakingBalance;

        // Calcular la recompensa basada en los bloques pasados y la participación del usuario
        uint256 reward = (REWARD_PER_BLOCK * blocksPassed * userShare) / 1e18;

        // Actualizar las recompensas pendientes y el checkpoint del usuario
        stakingInfo[beneficiary].pendingRewards += reward;
        stakingInfo[beneficiary].checkpoint = block.number;

        return reward;
    }
}
