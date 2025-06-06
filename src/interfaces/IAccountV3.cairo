// *************************************************************************
//                              ACCOUNT V3 INTERFACE
// *************************************************************************
use starknet::ContractAddress;

#[starknet::interface]
pub trait IAccountV3<TContractState> {
    fn on_erc721_received(
        self: @TContractState,
        operator: ContractAddress,
        from: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    ) -> felt252;
    fn onERC721Received(
        self: @TContractState,
        operator: ContractAddress,
        from: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    ) -> felt252;
    fn context(self: @TContractState) -> (ContractAddress, felt252, felt252);
}
