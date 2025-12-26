const core = require("@actions/core");

async function run() {
  try {
    const name = core.getInput("name");
    if (!name) {
      throw new Error("Name input is required");
    }

    console.log(`Hello ${name}`);
    core.setOutput("greeting", `Hello ${name}`);
  } catch (error) {
    core.setFailed(error.message);
  }
}

module.exports = { run };
