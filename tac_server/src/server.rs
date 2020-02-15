use tonic::{transport::Server, Request, Response, Status};

use multiplayer_game::multiplayer_server::{Multiplayer, MultiplayerServer};
use multiplayer_game::{MakeMoveRequest, MakeMoveReply};

pub mod multiplayer_game {
    tonic::include_proto!("multiplayer_game"); // The string specified here must match the proto package name
}

#[derive(Debug, Default)]
pub struct MyMultiplayer {}

#[tonic::async_trait]
impl Multiplayer for MyMultiplayer {
    async fn make_move(
        &self,
        request: Request<MakeMoveRequest>, // Accept request of type HelloRequest
    ) -> Result<Response<MakeMoveReply>, Status> { // Return an instance of type HelloReply
        println!("Got a request: {:?}", request);

        let reply = multiplayer_game::MakeMoveReply{};

        Ok(Response::new(reply)) // Send back our formatted greeting
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "[::1]:50051".parse()?;
    let greeter = MyMultiplayer::default();

    Server::builder()
        .add_service(MultiplayerServer::new(greeter))
        .serve(addr)
        .await?;

    Ok(())
}
