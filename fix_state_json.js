const fs = require("fs");

function hexToInt(val) {
  if (typeof val === "string" && /^0x[0-9a-fA-F]+$/.test(val)) {
    return parseInt(val, 16);
  }
  return val;
}

function fixBlockFields(block) {
  // Convert known numeric fields from hex string to number
  const numericFields = [
    "number",
    "timestamp",
    "gas_limit",
    "gasLimit",
    "basefee",
    "baseFeePerGas",
    "difficulty",
    "best_block_number",
  ];
  for (const key of numericFields) {
    if (block[key] !== undefined) {
      block[key] = hexToInt(block[key]);
    }
  }
  // Rename 'coinbase' to 'beneficiary' if present
  if (block.coinbase) {
    block.beneficiary = block.coinbase;
    delete block.coinbase;
  }
  return block;
}

function fixBlocksArray(blocks) {
  // Each block should have a 'header' key if not present
  return blocks.map((b) => {
    if (b.header) {
      // Fix numeric fields in header
      fixBlockFields(b.header);
      return b;
    } else {
      // If only 'ommers' present, wrap in header
      return {
        header: fixBlockFields(b),
        transactions: b.transactions || [],
        ommers: b.ommers || [],
      };
    }
  });
}

function fixBestBlockNumber(val) {
  if (typeof val === "string" && /^0x[0-9a-fA-F]+$/.test(val)) {
    return parseInt(val, 16);
  }
  return val;
}

function main() {
  const input = "dummystate.json";
  const output = "dummystate_fixed.json";
  const data = JSON.parse(fs.readFileSync(input, "utf8"));

  // Fix top-level block
  if (data.block) {
    fixBlockFields(data.block);
  }

  // Fix best_block_number
  if (data.best_block_number !== undefined) {
    data.best_block_number = fixBestBlockNumber(data.best_block_number);
  }

  // Fix blocks array
  if (Array.isArray(data.blocks)) {
    data.blocks = fixBlocksArray(data.blocks);
  }

  // Write out the fixed file
  fs.writeFileSync(output, JSON.stringify(data, null, 2));
  console.log(`Fixed file written to ${output}`);
}

main();
