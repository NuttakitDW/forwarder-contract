const { ethers } = require('ethers');
require('dotenv').config();

const provider = new ethers.providers.JsonRpcProvider('https://rpc.ankr.com/polygon_amoy');
const usdtContractAddress = '0x0408930a9cb696645e091250092fa437b26a7e91';
const forwarderContractAddress = '0x1ddF2D721847fF92E2C0f3F4872EA07b96458c12';
const privateKey = process.env.PRIVATE_KEY;

const wallet = new ethers.Wallet(privateKey, provider);

const usdtAbi = [
    "function balanceOf(address owner) view returns (uint256)",
    "function decimals() view returns (uint8)"
];
const forwarderAbi = ["function flushTokens(address token) external"];

const usdtContract = new ethers.Contract(usdtContractAddress, usdtAbi, provider);
const forwarderContract = new ethers.Contract(forwarderContractAddress, forwarderAbi, wallet);

let isProcessing = false;

async function checkBalanceAndTriggerFlush() {
    if (isProcessing) {
        console.log("Transaction is still being processed. Waiting...");
        return;
    }

    try {
        isProcessing = true;

        const balance = await usdtContract.balanceOf(forwarderContractAddress);
        const decimals = await usdtContract.decimals();
        const balanceInUSDT = ethers.utils.formatUnits(balance, decimals);

        console.log(`Current USDT balance: ${balanceInUSDT} USDT`);

        if (parseFloat(balanceInUSDT) > 0) {
            console.log('Balance is greater than 0. Triggering flushTokens() function...');

            // Fetch the current nonce for the wallet (use 'pending' to avoid nonce conflicts)
            const nonce = await wallet.getTransactionCount('pending');

            // Send the transaction with the correct nonce
            const tx = await forwarderContract.flushTokens(usdtContractAddress, {
                nonce: nonce,
                gasPrice: ethers.utils.parseUnits('50', 'gwei') // Set a higher gas price to prioritize
            });
            console.log(`Transaction sent: ${tx.hash}`);

            await tx.wait(); // Wait until the transaction is confirmed
            console.log(`Transaction confirmed: ${tx.hash}`);

            console.log(`Flushed ${balanceInUSDT} USDT from the forwarder contract.`);
        } else {
            console.log('Balance is 0. No action needed.');
        }
    } catch (error) {
        console.error('Error checking balance or triggering flushTokens:', error);
    } finally {
        isProcessing = false;
    }
}

setInterval(checkBalanceAndTriggerFlush, 1000);
