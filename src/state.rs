use crate::config::CONFIG;
use crate::nostr::Nostr;
use anyhow::Result;

use multimint::MultiMint;
use tracing::info;

#[derive(Clone)]
pub struct AppState {
    pub mm: MultiMint,
    pub nostr: Nostr,
}

impl AppState {
    pub async fn new() -> Result<Self> {
        let mut mm = MultiMint::new(CONFIG.fm_db_path.clone()).await?;
        for invite_code in &CONFIG.federation_invite_codes {
            match mm.register_new(invite_code.clone(), None).await {
                Ok(_) => info!("Registered federation: {}", invite_code),
                Err(e) => info!("federation already registered: {}", e),
            }
        }

        let nostr = Nostr::new(&CONFIG.nostr_nsec)?;

        nostr.add_relays(&CONFIG.nostr_relays).await?;
        nostr.client.connect().await;

        Ok(Self { mm, nostr })
    }
}
