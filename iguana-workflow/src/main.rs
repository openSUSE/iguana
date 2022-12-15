use clap::Parser;
use env_logger::Env;
use log::{error, info};

use std::fs;
use std::path::Path;
use std::process::exit;

use crate::workflow::{do_workflow, WorkflowOptions};

mod engines;
mod workflow;

#[derive(Parser, Debug)]
#[clap(version, about, long_about = None)]
/// Prepare, run and collect iguana containers based on passed iguana workflow file
struct Args {
    /// File with iguana workflow
    #[clap(value_parser, forbid_empty_values = true)]
    workflow: String,

    /// Newroot mount directory
    #[clap(short, long, value_parser, default_value = "/sysroot")]
    newroot: String,

    /// Do not run any action
    #[clap(long, takes_value = false)]
    dry_run: bool,

    /// Log level
    #[clap(long, default_value = "info", value_parser)]
    log_level: String,

    /// Container debugging
    /// If enabled, containers and their images will not be removed after run
    #[clap(long, takes_value = false)]
    debug: bool,

    /// Run privileged containers
    #[clap(short, long, takes_value = false)]
    unprivileged: bool,
}

/// Tracking results of individual job runs

fn main() {
    let args = Args::parse();
    env_logger::Builder::from_env(Env::default().default_filter_or(args.log_level)).init();

    let workflow_file = args.workflow;
    // Is workflow URL or file
    info!("Using workflow file {}", workflow_file);
    if !Path::is_file(Path::new(&workflow_file)) {
        error!("No such file: {}", workflow_file);
        exit(1);
    }

    let workflow_data = fs::read_to_string(workflow_file).expect("Unable to open workflow file");

    let opts = WorkflowOptions {
        debug: args.debug,
        dry_run: args.dry_run,
        privileged: !args.unprivileged,
    };

    if let Err(e) = do_workflow(workflow_data, &opts) {
        error!("{}", e);
        exit(1);
    } else {
        info!("Iguana workflow finished successfully");
        exit(0);
    }
}
