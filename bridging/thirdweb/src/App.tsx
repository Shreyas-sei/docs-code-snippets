import { ThirdwebProvider, ConnectButton } from "thirdweb/react";
import { client } from "./client";
import { BridgeComponent } from "./BridgeComponent";

function App() {
  return (
    <ThirdwebProvider>
      <div className="app">
        <h1>Thirdweb Bridge to Sei</h1>
        <ConnectButton client={client} />
        <BridgeComponent />
      </div>
    </ThirdwebProvider>
  );
}

export default App;
