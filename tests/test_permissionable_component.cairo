// *************************************************************************
//                              PERMISSIONABLE COMPONENT TEST
// *************************************************************************
use starknet::{ContractAddress, account::Call};
use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait
};
use token_bound_accounts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use token_bound_accounts::interfaces::IPermissionable::{
    IPermissionableDispatcher, IPermissionableDispatcherTrait
};
use token_bound_accounts::interfaces::IExecutable::{
    IExecutableDispatcher, IExecutableDispatcherTrait
};

use token_bound_accounts::interfaces::IUpgradeable::{
    IUpgradeableDispatcher, IUpgradeableDispatcherTrait
};
use token_bound_accounts::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
use token_bound_accounts::components::permissionable::permissionable::PermissionableComponent;

use token_bound_accounts::test_helper::{
    hello_starknet::{IHelloStarknetDispatcher, IHelloStarknetDispatcherTrait}
};

const ACCOUNT1: felt252 = 5729;
const ACCOUNT2: felt252 = 1234;
const ACCOUNT3: felt252 = 6908;
const ACCOUNT4: felt252 = 4697;

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, ContractAddress) {
    // deploy erc721 helper contract
    let erc721_contract = declare("ERC721").unwrap().contract_class();
    let mut erc721_constructor_calldata = array!['tokenbound', 'TBA'];
    let (erc721_contract_address, _) = erc721_contract
        .deploy(@erc721_constructor_calldata)
        .unwrap();

    // deploy recipient contract
    let account_contract = declare("SimpleAccount").unwrap().contract_class();
    let (recipient, _) = account_contract
        .deploy(
            @array![883045738439352841478194533192765345509759306772397516907181243450667673002]
        )
        .unwrap();

    // mint a new token
    let dispatcher = IERC721Dispatcher { contract_address: erc721_contract_address };
    dispatcher.mint(recipient, 1.try_into().unwrap());

    // deploy registry contract
    let registry_contract = declare("Registry").unwrap().contract_class();
    let (registry_contract_address, _) = registry_contract.deploy(@array![]).unwrap();

    // deploy account contract
    let account_contract = declare("AccountPreset").unwrap().contract_class();
    let mut acct_constructor_calldata = array![
        erc721_contract_address.try_into().unwrap(),
        1,
        0,
        registry_contract_address.try_into().unwrap(),
        (*account_contract.class_hash).into(),
        20
    ];
    let (account_contract_address, _) = account_contract
        .deploy(@acct_constructor_calldata)
        .unwrap();

    (account_contract_address, erc721_contract_address)
}

// *************************************************************************
//                              TESTS
// *************************************************************************
#[test]
#[should_panic(expected: ('Account: invalid length',))]
fn test_should_fail_if_unequal_permissioned_addresses_and_permissions() {
    let (contract_address, _) = __setup__();
    let acct_dispatcher = IAccountDispatcher { contract_address: contract_address };

    let owner = acct_dispatcher.owner();

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(ACCOUNT2.try_into().unwrap());
    permission_addresses.append(ACCOUNT3.try_into().unwrap());
    permission_addresses.append(ACCOUNT4.try_into().unwrap());

    let mut permissions = ArrayTrait::new();
    permissions.append(true);
    permissions.append(true);

    let permissionable_dispatcher = IPermissionableDispatcher { contract_address };

    start_cheat_caller_address(contract_address, owner);
    permissionable_dispatcher.set_permission(permission_addresses, permissions)
}

#[test]
fn test_set_permissions() {
    let (contract_address, _) = __setup__();
    let acct_dispatcher = IAccountDispatcher { contract_address: contract_address };

    let owner = acct_dispatcher.owner();

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(ACCOUNT2.try_into().unwrap());
    permission_addresses.append(ACCOUNT3.try_into().unwrap());
    permission_addresses.append(ACCOUNT4.try_into().unwrap());

    let mut permissions = ArrayTrait::new();
    permissions.append(true);
    permissions.append(true);
    permissions.append(true);

    start_cheat_caller_address(contract_address, owner);

    let permissionable_dispatcher = IPermissionableDispatcher { contract_address };
    permissionable_dispatcher.set_permission(permission_addresses, permissions);

    let has_permission = permissionable_dispatcher
        .has_permission(owner, ACCOUNT2.try_into().unwrap());

    assert(has_permission == true, 'Account: not permitted');
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_has_permissions() {
    let (contract_address, _) = __setup__();
    let acct_dispatcher = IAccountDispatcher { contract_address: contract_address };

    let owner = acct_dispatcher.owner();

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(ACCOUNT2.try_into().unwrap());
    permission_addresses.append(ACCOUNT3.try_into().unwrap());
    permission_addresses.append(ACCOUNT4.try_into().unwrap());

    let mut permissions = ArrayTrait::new();
    permissions.append(true);
    permissions.append(true);
    permissions.append(false);

    start_cheat_caller_address(contract_address, owner);

    let permissionable_dispatcher = IPermissionableDispatcher { contract_address };
    permissionable_dispatcher.set_permission(permission_addresses, permissions);

    let has_permission2 = permissionable_dispatcher
        .has_permission(owner, ACCOUNT2.try_into().unwrap());
    assert(has_permission2 == true, 'Account: not permitted');

    let has_permission3 = permissionable_dispatcher
        .has_permission(owner, ACCOUNT3.try_into().unwrap());
    assert(has_permission3 == true, 'Account: not permitted');

    let has_permission4 = permissionable_dispatcher
        .has_permission(owner, ACCOUNT4.try_into().unwrap());
    assert(has_permission4 == false, 'Account: permitted');

    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_set_permission_emits_event() {
    let (contract_address, _) = __setup__();
    let acct_dispatcher = IAccountDispatcher { contract_address: contract_address };

    let owner = acct_dispatcher.owner();
    // spy on emitted events
    let mut spy = spy_events();

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(ACCOUNT2.try_into().unwrap());
    permission_addresses.append(ACCOUNT3.try_into().unwrap());
    permission_addresses.append(ACCOUNT4.try_into().unwrap());

    let mut permissions = ArrayTrait::new();
    permissions.append(true);
    permissions.append(true);
    permissions.append(true);

    start_cheat_caller_address(contract_address, owner);

    let permissionable_dispatcher = IPermissionableDispatcher { contract_address };
    permissionable_dispatcher.set_permission(permission_addresses, permissions);

    // check events are emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PermissionableComponent::Event::PermissionUpdated(
                        PermissionableComponent::PermissionUpdated {
                            owner: owner,
                            permissioned_address: ACCOUNT4.try_into().unwrap(),
                            has_permission: true
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_permissioned_accounts_can_execute() {
    let (contract_address, _) = __setup__();
    let acct_dispatcher = IAccountDispatcher { contract_address: contract_address };
    let executable_dispatcher = IExecutableDispatcher { contract_address };
    let owner = acct_dispatcher.owner();

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(ACCOUNT2.try_into().unwrap());
    permission_addresses.append(ACCOUNT3.try_into().unwrap());
    permission_addresses.append(ACCOUNT4.try_into().unwrap());

    let mut permissions = ArrayTrait::new();
    permissions.append(true);
    permissions.append(true);
    permissions.append(false);

    start_cheat_caller_address(contract_address, owner);

    let permissionable_dispatcher = IPermissionableDispatcher { contract_address };
    permissionable_dispatcher.set_permission(permission_addresses, permissions);

    let has_permission2 = permissionable_dispatcher
        .has_permission(owner, ACCOUNT2.try_into().unwrap());
    assert(has_permission2 == true, 'Account: permitted');

    // deploy `HelloStarknet` contract for testing
    let test_contract = declare("HelloStarknet").unwrap().contract_class();
    let (test_address, _) = test_contract.deploy(@array![]).unwrap();

    // craft calldata for call array
    let mut calldata = array![100].span();
    let call = Call {
        to: test_address,
        selector: 1530486729947006463063166157847785599120665941190480211966374137237989315360,
        calldata: calldata
    };

    start_cheat_caller_address(contract_address, ACCOUNT2.try_into().unwrap());
    executable_dispatcher.execute(array![call]);
    // check test contract state was updated
    let test_dispatcher = IHelloStarknetDispatcher { contract_address: test_address };
    let balance = test_dispatcher.get_balance();
    assert(balance == 100, 'execute was not successful');
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_permissioned_accounts_can_upgrade() {
    let (contract_address, erc721_contract_address) = __setup__();
    let acct_dispatcher = IAccountDispatcher { contract_address: contract_address };
    let owner = acct_dispatcher.owner();

    // get token owner
    let token_dispatcher = IERC721Dispatcher { contract_address: erc721_contract_address };
    let token_owner = token_dispatcher.ownerOf(1.try_into().unwrap());

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(ACCOUNT2.try_into().unwrap());
    permission_addresses.append(token_owner);

    let mut permissions = ArrayTrait::new();
    permissions.append(true);
    permissions.append(true);

    start_cheat_caller_address(contract_address, owner);

    let permissionable_dispatcher = IPermissionableDispatcher { contract_address };
    permissionable_dispatcher.set_permission(permission_addresses, permissions);

    let has_permission2 = permissionable_dispatcher.has_permission(owner, token_owner);
    assert(has_permission2 == true, 'Account: permitted');

    stop_cheat_caller_address(contract_address);

    let upgraded_account_class = declare("UpgradedAccount").unwrap().contract_class();
    let new_class_hash = *upgraded_account_class.class_hash;

    // call the upgrade function
    let dispatcher = IUpgradeableDispatcher { contract_address };

    start_cheat_caller_address(contract_address, token_owner);
    dispatcher.upgrade(new_class_hash);
    stop_cheat_caller_address(contract_address);
}

