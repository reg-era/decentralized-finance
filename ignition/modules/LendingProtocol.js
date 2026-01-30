import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LendingProtocolModule = buildModule("LendingProtocolModule", (m) => {
    // Deploy Oracle
    const oracle = m.contract("Oracle");

    // Deploy Tokens
    const stable = m.contract("Stable");
    const volatile = m.contract("Volatile");
    const lstable = m.contract("lStable");
    const lvolatile = m.contract("lVolatile");

    // Deploy LendingPlatform
    const lending = m.contract("LendingPlatform", [
        stable,
        volatile,
        lstable,
        lvolatile,
    ]);

    // Post-deployment calls
    // Transfer ownership of lTokens to LendingPlatform
    m.call(lstable, "transferOwnership", [lending]);
    m.call(lvolatile, "transferOwnership", [lending]);

    // Register Oracle
    m.call(lending, "registerOracle", [oracle]);

    return {
        oracle,
        stable,
        volatile,
        lstable,
        lvolatile,
        lending,
    };
});

export default LendingProtocolModule;
