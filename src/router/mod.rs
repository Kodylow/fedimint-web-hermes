use anyhow::Result;
use askama::Template;
use askama_axum::IntoResponse;
use axum::extract::State;
use axum::routing::get;
use axum::Router;

use crate::state::AppState;

pub async fn create_router(state: AppState) -> Result<Router> {
    let app = Router::new()
        .route("/", get(handle_index_html))
        // .route("/health", get(|| async { "OK" }))
        // .route("/invoices", get(invoices::handle_invoices))
        // .route(
        //     "/.well-known/lnurlp/:username",
        //     get(lnurlp::well_known::handle_well_known),
        // )
        // .route(
        //     "/lnurlp/:username/callback",
        //     get(lnurlp::callback::handle_callback),
        // )
        // .route(
        //     "/lnurlp/:username/verify/:op_id",
        //     get(lnurlp::verify::handle_verify),
        // )
        .with_state(state);

    Ok(app)
}

#[derive(Template)]
#[template(path = "index.html")]
pub struct HtmlTemplate {}

pub async fn handle_index_html(State(_): State<AppState>) -> HtmlTemplate {
    HtmlTemplate {}
}
