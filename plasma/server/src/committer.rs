use std::sync::mpsc::{channel, Sender, Receiver};
use plasma::eth_client::{TxMeta};
use super::storage::{ConnectionPool, StorageProcessor};
use super::server_models::{Operation, Action, ProverRequest, CommitRequest};

pub fn run_committer(
    rx_for_ops: Receiver<CommitRequest>, 
    tx_for_eth: Sender<Operation>,
    tx_for_proof_requests: Sender<ProverRequest>,
    pool: ConnectionPool,
) {

    let storage = pool.access_storage().expect("db connection failed for committer");;

    // request unverified proofs
    let ops = storage.load_unverified_commitments().expect("committer must load pending ops from db");
    for op in ops {
        //let op: Operation = serde_json::from_value(pending_op.data).unwrap();
        if let Action::Commit = op.action {
            tx_for_proof_requests.send(ProverRequest(op.block.block_number)).expect("must send a proof request for pending operations");
        }
    }

    let mut last_verified_block = storage.get_last_verified_block().expect("db failed");
    for mut req in rx_for_ops {
        match req {
            CommitRequest::NewBlock{block, accounts_updated} => {
                let op = Operation{
                    action: Action::Commit, 
                    block, 
                    accounts_updated: Some(accounts_updated), 
                    tx_meta: None
                };
                let op = storage.execute_operation(&op).expect("committer must commit the op into db");
                tx_for_proof_requests.send(ProverRequest(op.block.block_number)).expect("must send a proof request");
                tx_for_eth.send(op).expect("must send an operation for commitment to ethereum");
            },
            CommitRequest::NewProof(block_number) => {
                if block_number == last_verified_block + 1 {
                    loop {
                        let block_number = last_verified_block + 1;
                        let proof = storage.load_proof(block_number);
                        if let Ok(proof) = proof {
                            let block = storage.load_committed_block(block_number).expect(format!("failed to load block #{}", block_number).as_str());
                            let op = Operation{
                                action: Action::Verify{proof}, 
                                block, 
                                accounts_updated: None, 
                                tx_meta: None
                            };
                            let op = storage.execute_operation(&op).expect("committer must commit the op into db");
                            tx_for_eth.send(op).expect("must send an operation for commitment to ethereum");
                            last_verified_block += 1;
                        } else {
                            break;
                        }
                    }
                }
            },
        };
    }
}
