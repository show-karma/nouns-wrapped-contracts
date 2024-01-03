// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {EIP712} from "solady/src/utils/EIP712.sol";
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {SignatureCheckerLib} from "solady/src/utils/SignatureCheckerLib.sol";

import {Renderer} from "./Renderer.sol";
import {LibDataURI} from "./LibDataURI.sol";

contract NounsWrapped is Ownable, ERC721, EIP712 {
    using LibDataURI for string;

    Renderer public renderer = new Renderer();

    /// @notice Caller provided incorrect payable amount
    error InvalidPayment();

    // /// @notice Caller provided invalid `Mint` signature
    // error InvalidSignature();

    // /// @notice emitted when owner changes the signer address
    // event SetSigner(address oldSigner, address newSigner);

    /// @notice emitted when owner changes the mint fee
    event SetMintFee(uint256 oldMintFee, uint256 newMintFee);

    // /// @notice EIP-712 typehash for `Mint` message
    // bytes32 internal constant MINT_TYPEHASH = keccak256(
    //     "Mint(address to,uint256 tokenId,uint24 mins,uint16 streak,string username)"
    // );

    /// @notice Fee in wei per mint
    uint256 public mintFee;

    /// @notice Last minted token ID
    uint256 public tokenIdCounter;

    // /// @notice Address authorized to sign `Mint` messages
    // address public signer;

    /// @notice Stats for a given tokenId
    /// @param props Number of props created
    /// @param sponsoredProps Number of props sponsored
    /// @param votes Number of votes cast
    /// @param username Username of caster
    struct WrappedStats {
        uint16 props;
        uint16 sponsoredProps;
        uint24 votes; 
        uint24 propHouseVotes;
        uint16 candProps;
        uint24 propsFeedback; 
        string username;
    }

    /// @notice Read stats by tokenId
    mapping(uint256 tokenId => WrappedStats) public statsOf;

    /// @notice Random seed by tokenId
    mapping(uint256 tokenId => uint32 seed) public seeds;

    /// @notice tokenId by owner
    mapping(address => uint256) public tokenIdOf;



    /// @notice Set owner, signer, and mint fee
    /// @param _owner Contract owner address
    // /// @param _signer Mint signer address
    /// @param _mintFee Fee in wei per mint
    constructor(
        address _owner, 
        // address _signer, 
        uint256 _mintFee
    ) {
        mintFee = _mintFee;
        tokenIdCounter = 0;
        _initializeOwner(_owner);
        // emit SetSigner(address(0), signer = _signer);
    }

    /// @notice Read token name
    function name() public pure override returns (string memory) {
        return "Nouns Wrapped 2023";
    }

    /// @notice Read token symbol
    function symbol() public pure override returns (string memory) {
        return unicode"NW 🎁2023";
    }

    /// @notice Read contract metadata
    /// @return Base64 encoded metadata data URI
    function contractURI() public view returns (string memory) {
        return renderer.contractJSON().toDataURI("application/json");
    }

    /// @notice Read token metadata
    /// @param tokenId Token/Nouns ID
    /// @return Base64 encoded metadata data URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        WrappedStats memory stats = statsOf[tokenId];
        return renderer.tokenJSON(
            seeds[tokenId], tokenId, stats.props, stats.sponsoredProps, stats.votes, stats.propHouseVotes, stats.candProps, stats.propsFeedback, stats.username
        ).toDataURI("application/json");
    }

    /// @notice Mint a Nouns Wrapped token.
    ///         Caller must send mintFee wei as msg.value.
    ///         Caller must provide an EIP-712 `Mint` signature.
    function mint(
        address to, 
        // bytes calldata sig
        WrappedStats calldata stats
    ) external payable {
        require(msg.value == mintFee, "NounsWrapped: incorrect payment");
        // Revert if user already has a token
        require(tokenIdOf[to] == 0, "NounsWrapped: user already has a token");
        // if (!_verifySignature(to, tokenId, stats, sig)) {
        //     revert InvalidSignature();
        // }
        tokenIdCounter++;
        uint256 _tokenId = tokenIdCounter;
        statsOf[_tokenId] = stats;
        seeds[_tokenId] = _seed(_tokenId); 
        _mint(to, _tokenId); 
        tokenIdOf[to] = _tokenId;
    }

    // /// @notice Set signer address. Only callable by owner.
    // /// @param _signer New signer address
    // function setSigner(address _signer) external onlyOwner {
    //     emit SetSigner(signer, signer = _signer);
    // }

    /// @notice Withdraw contract balance. Only callable by owner.
    function withdrawBalance(address to) external onlyOwner {
        SafeTransferLib.safeTransferAllETH(to);
    }

    /// @notice Change mint fee. Only callable by owner.
    /// @param _mintFee New mint fee
    function setMintFee(uint256 _mintFee) external onlyOwner {
        emit SetMintFee(mintFee, mintFee = _mintFee);
    }

    /// @dev Generate token PRNG seed.
    function _seed(uint256 tokenId) internal view returns (uint32) {
        return uint32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp, blockhash(block.number - 1), tokenId
                    )
                )
            )
        );
    }

    /// @dev EIP-712 domain name and contract version.
    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory, string memory)
    {
        return ("Nouns Wrapped 2023", "1");
    }

    // Burn
    function burn(uint256 tokenId) external {
        // Revert if user is not owner of contract or the token
        require(msg.sender == owner() || tokenIdOf[msg.sender] == tokenId, "NounsWrapped: user is not owner of contract or the token");
        _burn(tokenId);
        delete statsOf[tokenId];
        delete seeds[tokenId];
        delete tokenIdOf[msg.sender];
    }

    // /// @dev Verify EIP-712 `Mint` signature.
    // function _verifySignature(
    //     address to,
    //     uint256 tokenId,
    //     WrappedStats calldata stats,
    //     bytes calldata sig
    // ) internal view returns (bool) {
    //     bytes32 digest = _hashTypedData(
    //         keccak256(
    //             abi.encode(
    //                 MINT_TYPEHASH,
    //                 to,
    //                 tokenId,
    //                 stats.mins,
    //                 stats.streak,
    //                 keccak256(bytes(stats.username))
    //             )
    //         )
    //     );
    //     return
    //         SignatureCheckerLib.isValidSignatureNowCalldata(signer, digest, sig);
    // }
}
