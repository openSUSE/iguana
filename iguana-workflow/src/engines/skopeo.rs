use log::debug;
use std::path::Path;
use std::process::Command;

use super::{ImageOps, Availability};
use crate::workflow::WorkflowOptions;

pub struct Skopeo;

const STORAGE_PATH: &str = "oci:/var/lib/containers/storage";
const SKOPEO_BIN: &str = "/usr/bin/skopeo";

impl Availability for Skopeo{
    fn is_available() -> Result<(), ()> {
        if Path::is_file(Path::new(SKOPEO_BIN)) {
            return Ok(())
        };
        return Err(())
    }
}

impl ImageOps for Skopeo{
    fn prepare_image(&self, image: &str, dry_run: bool) -> Result<(), String> {
        let mut skopeo = Command::new(SKOPEO_BIN);
        let cmd = skopeo.args(["copy", "--", image, STORAGE_PATH]);

        debug!("{cmd:?}");
        if !dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }

    fn clean_image(&self, image: &str, opts: &WorkflowOptions) -> Result<(), String> {
        if opts.debug {
            debug!("Not cleaning job image {image} because of debug option");
            return Ok(());
        }

        let mut skopeo = Command::new(SKOPEO_BIN);
        let cmd = skopeo.args(["delete", "--force", "--", image]);
        debug!("{cmd:?}");
        if !opts.dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }
}