// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}

abstract contract ERC20 is IERC20, Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    mapping(address => uint256) public _balanceOf;
    mapping(address => mapping(address => uint256)) public _allowance;
    
    uint256 public _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint8 public burnRateOnFee = 4;

    address public ownerWallet = 0x894e445fFA315632a003104FBacD9139aEb0cb87;
    address public stakingAddress = 0xdbd6Be57eaBE934B6CF8F226548F89A9d1772A8c;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _totalSupply = _initialSupply;
        // Assign the initial supply to the deployer's address
        _balanceOf[msg.sender] = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply); // Emit a Transfer event from the zero address to mark the creation of tokens
    }

    function totalSupply() public view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf (address account) public view override returns (uint256){
        return _balanceOf[account];
    }

    function transfer(address recipient, uint256 amount)
        external override 
        returns (bool)
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balanceOf[msg.sender] >= amount, "Insufficient Tokens");
        
        uint256 burn_fee = recipient == stakingAddress || msg.sender == ownerWallet ? 0 : (amount * burnRateOnFee) / 100;
        uint256 sendAmount = amount - burn_fee;

        _balanceOf[msg.sender] -= amount;
        _balanceOf[recipient] += sendAmount;
        if (burn_fee > 0) {
            _totalSupply -= burn_fee;
            emit Burn(msg.sender, burn_fee);
        } 
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {  
        require(sender != address(0), "ERC20: transfer from the zero address");  
        require(recipient != address(0), "ERC20: transfer to the zero address");  
        require(amount <= _allowance[sender][msg.sender], "ERC20: transfer amount exceeds allowance");  
        require(_balanceOf[sender] >= amount, "ERC20: transfer amount exceeds balance");  

        _balanceOf[sender] -= amount;  
        _balanceOf[recipient] += amount;  
        _allowance[sender][msg.sender] -= amount;  

        emit Transfer(sender, recipient, amount);  
        return true;  
    }  

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowance[owner][spender];
    }
}

contract Giftereum is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply)
        ERC20(name, symbol, decimals, initialSupply * 10 ** decimals){}

    function setFeeRate(uint8 newBurnFee) external onlyOwner {
        burnRateOnFee = newBurnFee;
    }

    function setOwnerWallets (address newOwner) external onlyOwner {
        require(newOwner != address(0), "Couldn't set none address");
        ownerWallet = newOwner;
    }

    function setStakingContractAddr (address newAddress) external onlyOwner {
        require(newAddress != address(0), "Couldn't set none address");
        stakingAddress = newAddress;
    }
}
