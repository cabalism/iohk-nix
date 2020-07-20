{lib, writeText, runCommand, jq}:
let
  mkEdgeTopology = {
    hostAddr ? "127.0.0.1"
  , port ? 3001
  , edgeHost ? "127.0.0.1"
  , edgeNodes ? []
  , edgePort ? if (edgeNodes != []) then 3001 else (if edgeHost == "127.0.0.1" then 7777 else 3001)
  , valency ? 1
  }:
  let
    mkProducers = map (edgeHost': { addr = edgeHost'; port = edgePort; inherit valency; }) edgeNodes;
    topology = {
      Producers = if (edgeNodes != []) then mkProducers else [
        {
          addr = edgeHost;
          port = edgePort;
          inherit valency;
        }
      ];
    };
  in builtins.toFile "topology.yaml" (builtins.toJSON topology);

  defaultLogConfig = import ./generic-log-config.nix;
  defaultExplorerLogConfig = import ./explorer-log-config.nix;
  defaultProxyLogConfig = import ./proxy-log-config.nix;

  mkProxyTopology = relay: writeText "proxy-topology-file" ''
    wallet:
      relays: [[{ host: ${relay} }]]
  '';
  environments = {
    mainnet = rec {
      useByronWallet = true;
      relays = "relays.cardano-mainnet.iohk.io";
      relaysNew = "relays-new.cardano-mainnet.iohk.io";
      edgeNodes = [
        "3.125.75.199"
        "18.177.103.105"
        "18.141.0.112"
        "52.14.58.121"
      ];
      edgePort = 3001;
      confKey = "mainnet_full";
      genesisFile = nodeConfig.ByronGenesisFile;
      genesisHash = "5f20df933584822601f9e3f8c024eb5eb252fe8cefb24d1317dc3d432e940ebb";
      genesisFileHfc = nodeConfig.ShelleyGenesisFile;
      private = false;
      networkConfig = import ./mainnet-config.nix;
      nodeConfig = networkConfig // defaultLogConfig;
      consensusProtocol = networkConfig.Protocol;
      submitApiConfig = {
        GenesisHash = genesisHash;
        inherit (networkConfig) RequiresNetworkMagic;
      } // defaultExplorerLogConfig;
    };
    mainnet_candidate = rec {
      useByronWallet = true;
      relaysNew = "relays-new.mainnet-candidate.dev.cardano.org";
      edgePort = 3001;
      private = false;
      networkConfig = import ./mainnet_candidate-config.nix;
      nodeConfig = networkConfig // defaultLogConfig;
      consensusProtocol = networkConfig.Protocol;
      genesisFile = nodeConfig.ByronGenesisFile;
      genesisHash = "214f022ffc617843a237a88104f7140bfc19e308ac38129d47fd0ab37d8c7591";
      genesisFileHfc = nodeConfig.ShelleyGenesisFile;
    };
    staging = rec {
      useByronWallet = true;
      relays = "relays.awstest.iohkdev.io";
      relaysNew = "relays-new.awstest.iohkdev.io";
      edgeNodes = [
        "3.125.10.61"
        "52.192.59.170"
        "18.136.145.112"
      ];
      edgePort = 3001;
      confKey = "mainnet_dryrun_full";
      genesisFile = nodeConfig.ByronGenesisFile;
      genesisHash = "c6a004d3d178f600cd8caa10abbebe1549bef878f0665aea2903472d5abf7323";
      genesisFileHfc = nodeConfig.ShelleyGenesisFile;
      private = false;
      networkConfig = import ./staging-config.nix;
      nodeConfig = networkConfig // defaultLogConfig;
      consensusProtocol = networkConfig.Protocol;
      submitApiConfig = {
        GenesisHash = genesisHash;
        inherit (networkConfig) RequiresNetworkMagic;
      } // defaultExplorerLogConfig;
    };
    testnet = rec {
      useByronWallet = true;
      relays = "relays.cardano-testnet.iohkdev.io";
      relaysNew = "relays-new.cardano-testnet.iohkdev.io";
      edgeNodes = [
        "3.125.94.58"
        "18.176.19.63"
        "13.251.186.36"
        "3.135.95.164"
      ];
      edgePort = 3001;
      confKey = "testnet_full";
      genesisFile = ./testnet-byron-genesis.json;
      genesisHash = "96fceff972c2c06bd3bb5243c39215333be6d56aaf4823073dca31afe5038471";
      private = false;
      networkConfig = import ./testnet-config.nix;
      nodeConfig = networkConfig // defaultLogConfig;
      consensusProtocol = networkConfig.Protocol;
      submitApiConfig = {
        GenesisHash = genesisHash;
        inherit (networkConfig) RequiresNetworkMagic;
      } // defaultExplorerLogConfig;
    };
    shelley_staging = rec {
      useByronWallet = true;
      relays = "relays.staging-shelley.dev.iohkdev.io";
      relaysNew = "relays-new.staging-shelley.dev.cardano.org";
      edgeNodes = [
        "3.125.23.159"
        "18.177.133.109"
        "18.141.119.164"
      ];
      edgePort = 3001;
      confKey = "shelley_staging_full";
      genesisFile = nodeConfig.ByronGenesisFile;
      genesisHash = "82995abf3e0e0f8ab9a6448875536a1cba305f3ddde18cd5ff54c32d7a5978c6";
      genesisFileHfc = nodeConfig.ShelleyGenesisFile;
      private = false;
      networkConfig = import ./shelley_staging-config.nix;
      nodeConfig = networkConfig // defaultLogConfig;
      consensusProtocol = networkConfig.Protocol;
      submitApiConfig = {
        GenesisHash = genesisHash;
        inherit (networkConfig) RequiresNetworkMagic;
      } // defaultExplorerLogConfig;
    };
    # used for daedalus/cardano-wallet for local development
    selfnode = rec {
      useByronWallet = true;
      private = false;
      networkConfig = import ./selfnode-config.nix;
      nodeConfig = networkConfig // defaultLogConfig;
      consensusProtocol = networkConfig.Protocol;
      genesisFile = ./selfnode-byron-genesis.json;
      delegationCertificate = ./selfnode.cert;
      signingKey = ./selfnode.key;
      topology = ./selfnode-topology.json;
    };
    shelley_selfnode = rec {
      useByronWallet = false;
      private = false;
      networkConfig = import ./shelley-selfnode/shelley_selfnode-config.nix;
      consensusProtocol = networkConfig.Protocol;
      nodeConfig = networkConfig // defaultLogConfig;
      genesisFile = ./shelley-selfnode/shelley_selfnode-shelley-genesis.json;
      operationalCertificate = ./shelley-selfnode/node-keys/node.opcert;
      kesKey = ./shelley-selfnode/node-keys/node-kes.skey;
      vrfKey = ./shelley-selfnode/node-keys/node-vrf.skey;
      utxo = {
        signing = ./shelley-selfnode/utxo-keys/utxo1.skey;
        verification = ./shelley-selfnode/utxo-keys/utxo1.vkey;
      };
      topology = ./selfnode-topology.json;
    };
    shelley_testnet = rec {
      useByronWallet = false;
      private = false;
      relaysNew = "relays-new.shelley-testnet.dev.cardano.org";
      networkConfig = import ./shelley_testnet-config.nix;
      consensusProtocol = networkConfig.Protocol;
      nodeConfig = defaultLogConfig // networkConfig;
      genesisFile = networkConfig.GenesisFile;
      genesisHash = "";
      edgePort = 3001;
    };
    shelley_qa = rec {
      useByronWallet = false;
      private = false;
      relaysNew = "relays-new.shelley-qa.dev.cardano.org";
      networkConfig = import ./shelley_qa-config.nix;
      consensusProtocol = networkConfig.Protocol;
      nodeConfig = defaultLogConfig // networkConfig;
      genesisFile = networkConfig.ByronGenesisFile;
      genesisFileHfc = networkConfig.ShelleyGenesisFile;
      genesisHash = "129fa7c21f52ecd7d7620000a43e2beba9910cce45b3a027a730023120162273";
      edgePort = 3001;
    };
    latency-tests = {
      useByronWallet = false;
      relays = "relays.latency-tests.aws.iohkdev.io";
      edgeNodes = [
        "18.231.36.12"
      ];
      edgePort = 3001;
      confKey = "latency_tests_full";
      genesisFile = ./latency-tests-byron-genesis.json;
      genesisHash = "c8b2ef02574d10bf23c2cd4a8c4022a9285f366af64b2544b317e2175b94f5a3";
      private = false;
    };
    mainnet-ci = {
      useByronWallet = false;
      relays = "";
      edgeNodes = [
        "10.1.0.8"
      ];
      edgePort = 3000;
      confKey = "mainnet_ci_full";
      genesisFile = ./mainnet-ci-byron-genesis.json;
      genesisHash = "12da51c484b5310fe26ca06ab24b94b323cde3698a0a50cb3f212abd08c2731e";
      private = false;
    };
  };
  # TODO: add flag to disable with forEnvironments instead of hard-coded list?
  forEnvironments = f: lib.mapAttrs
    (name: env: f (env // { inherit name; }))
    (builtins.removeAttrs environments [ "mainnet-ci" "latency-tests" ]);
  forEnvironmentsCustom = f: environments: lib.mapAttrs
    (name: env: f (env // { inherit name; }))
    environments;

  cardanoConfig = ./.;

  protNames = {
    RealPBFT = { n = "byron"; };
    TPraos   = { n = "shelley"; };
    Cardano  = { n = "byron"; nHfc = "shelley"; };
  };

  configHtml = environments:
    ''
    <!DOCTYPE html>
    <html>
      <head>
        <title>Cardano Configurations</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.8.0/css/bulma.min.css">
        <script defer src="https://use.fontawesome.com/releases/v5.3.1/js/all.js"></script>
      </head>
      <body>
        <section class="hero is-small is-primary">
          <div class="hero-body">
            <div class="container">
              <h1 class="title is-1">
                Cardano
              </h1>
              <h2 class="subtitle is-3">
                Configurations
              </h2>
            </div>
          </div>
        </section>

        <section class="section">
          <div class="container">
            <div class="table-container">
              <table class="table is-narrow is-fullwidth">
                <thead>
                  <tr>
                    <th>Cluster</th>
                    <th>Config</th>
                  </tr>
                </thead>
                <tbody>
                  ${toString (lib.mapAttrsToList (env: value:
                    let p = value.consensusProtocol;
                    in ''
                    <tr>
                      <td>${env}</td>
                      <td>
                        <div class="buttons has-addons">
                          <a class="button is-primary" href="${env}-config.json">config</a>
                          <a class="button is-info" href="${env}-${protNames.${p}.n}-genesis.json">${protNames.${p}.n}Genesis</a>
                          ${if p == "Cardano" then ''
                            <a class="button is-info" href="${env}-${protNames.${p}.nHfc}-genesis.json">${protNames.${p}.nHfc}Genesis</a>
                          '' else ""}
                          <a class="button is-info" href="${env}-topology.json">topology</a>
                        </div>
                      </td>
                    </tr>
                    ''
                  ) environments) }
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </body>
    </html>
  '';

  # Any environments using the HFC protocol of "Cardano" need a second genesis file attribute of
  # genesisFileHfc in order to generate the html table in mkConfigHtml
  mkConfigHtml = environments: runCommand "cardano-html" { buildInputs = [ jq ]; } ''
    mkdir -p $out/nix-support
    cp ${writeText "config.html" (configHtml environments)} $out/index.html
    ${
      toString (lib.mapAttrsToList (env: value:
        let p = value.consensusProtocol;
        in ''
          ${if p != "Cardano" then ''
            ${jq}/bin/jq . < ${__toFile "${env}-config.json" (__toJSON (value.nodeConfig // {
              GenesisFile = "${env}-${protNames.${p}.n}-genesis.json";
            }))} > $out/${env}-config.json
          '' else ''
            ${jq}/bin/jq . < ${__toFile "${env}-config.json" (__toJSON (value.nodeConfig // {
              ByronGenesisFile = "${env}-${protNames.${p}.n}-genesis.json";
              ShelleyGenesisFile = "${env}-${protNames.${p}.nHfc}-genesis.json";
            }))} > $out/${env}-config.json
          ''}
          ${jq}/bin/jq . < ${value.genesisFile} > $out/${env}-${protNames.${p}.n}-genesis.json
          ${if p == "Cardano" then "${jq}/bin/jq . < ${value.genesisFileHfc} > $out/${env}-${protNames.${p}.nHfc}-genesis.json" else ""}
          ${jq}/bin/jq . < ${mkEdgeTopology { edgeNodes = [ value.relaysNew ]; valency = 2; }} > $out/${env}-topology.json
        ''
      ) environments )
    }
    echo "report cardano $out index.html" > $out/nix-support/hydra-build-products
  '';

in {
  inherit environments forEnvironments forEnvironmentsCustom mkEdgeTopology mkProxyTopology cardanoConfig defaultLogConfig defaultExplorerLogConfig defaultProxyLogConfig mkConfigHtml;
}
