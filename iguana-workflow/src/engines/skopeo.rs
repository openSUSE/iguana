use log::debug;
use std::collections::hash_map::DefaultHasher;
use std::fs::{create_dir, remove_dir_all};
use std::hash::{Hash, Hasher};
use std::{path::Path, collections::HashMap};
use std::process::Command;

use super::{ImageOps, Availability};
use crate::workflow::WorkflowOptions;

const STORAGE_PATH: &str = "/var/lib/containers/storage";
const SKOPEO_BIN: &str = "/usr/bin/skopeo";

fn create_hash(msg: &str) -> u64 {
    let mut hasher = DefaultHasher::new();
    msg.hash(&mut hasher);
    hasher.finish()
}
pub struct Skopeo {
    image_list: HashMap<u64, u8>
}

impl Skopeo {
    pub fn new() -> Skopeo {
        Skopeo { image_list: HashMap::new() }
    }
}

impl Availability for Skopeo{
    fn is_available() -> Result<(), ()> {
        debug!("Checking Skopeo availability");
        if Path::is_file(Path::new(SKOPEO_BIN)) {
            debug!("Skopeo available");
            return Ok(())
        };
        debug!("Skopeo not available");
        return Err(())
    }
}

impl ImageOps for Skopeo{
    fn prepare_image(&mut self, image: &str, dry_run: bool) -> Result<(), String> {
        // First we calculate hash of image name and check if it is not used already
        let image_name_hash = create_hash(image);
        if let Some(usage) = self.image_list.get_mut(&image_name_hash) {
            *usage += 1;
            debug!("Reusing image {image}");
            return Ok(())
        }
        // Create new dir under STORAGE_PATH
        debug!("Creating dir for image: {STORAGE_PATH}/{image_name_hash}");
        if !dry_run {
            if let Err(e) = create_dir(format!("{STORAGE_PATH}/{image_name_hash}")) {
                return Err(e.to_string());
            }
        }

        // Use skopeo to copy image from remote registry to local path
        let mut skopeo = Command::new(SKOPEO_BIN);
        let image_url =  if image.starts_with("docker://") {
            image.to_string()
        }
        else {
            format!("docker://{image}")
        };
        let cmd = skopeo.args(["copy", "--", &image_url,
            format!("oci:{STORAGE_PATH}/{image_name_hash}").as_str()]);

        debug!("{cmd:?}");
        if !dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        // Add image usage only if skopeo successfuly finishes
        self.image_list.insert(image_name_hash, 1);
        Ok(())
    }

    fn clean_image(&mut self, image: &str, opts: &WorkflowOptions) -> Result<(), String> {
        if opts.debug {
            debug!("Not cleaning job image {image} because of debug option");
            return Ok(());
        }
        let image_name_hash = create_hash(image);
        if let Some(usage) = self.image_list.get_mut(&image_name_hash) {
            if *usage > 1 {
                debug!("Image {image} used with multiple times, just decreasing usage");
                *usage -= 1;
                return Ok(())
            }
            debug!("Removing files for image {image}");
            if let Err(e) = remove_dir_all(format!("{STORAGE_PATH}/{image_name_hash}")) {
                return Err(e.to_string());
            }
            self.image_list.remove(&image_name_hash);
            return Ok(())
        }
        Err(format!("Image mapping not found for image {image}"))
    }
}