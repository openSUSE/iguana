use log::debug;
use std::collections::HashMap;
use std::collections::{HashSet, hash_map::DefaultHasher};
use std::fs::{create_dir_all, remove_dir_all};
use std::hash::{Hash, Hasher};
use std::path::Path;

use super::{Availability, VolumeOps};
use crate::workflow::WorkflowOptions;

const VOLUME_BASEDIR: &str = "/run/iguana-volumes";

fn create_hash(msg: &str) -> u64 {
    let mut hasher = DefaultHasher::new();
    msg.hash(&mut hasher);
    hasher.finish()
}

struct Volume {
    path: String,
    created: bool,
    usage: u8
}

pub struct LocalVolumes {
    // Volume list is hashed by volume name and value is directory of the volume
    volume_list: HashMap<u64, Volume>
}

impl LocalVolumes {
    pub fn new() -> LocalVolumes {
        LocalVolumes { volume_list: HashMap::new() }
    }
}

impl Availability for LocalVolumes{
    fn is_available() -> Result<(), ()> {
        debug!("Local volumes available");
        return Ok(())
    }
}

impl VolumeOps for LocalVolumes {
    fn prepare_volume(&mut self, name: &str, opts: &WorkflowOptions) -> Result<(), String> {
        let dry_run = opts.dry_run;
        let volume_name_hash = create_hash(name);
        if let Some(volume) = self.volume_list.get_mut(&volume_name_hash) {
            volume.usage += 1;
            debug!("Reusing volume {name}");
            return Ok(())
        }
        let vol_path = format!("{VOLUME_BASEDIR}/{volume_name_hash}");
        if Path::new(&vol_path).is_dir() {
            debug!("Volume {name} is existing directory");
            let vol = Volume {
                path: vol_path,
                created: false,
                usage: 1
            };
            self.volume_list.insert(volume_name_hash, vol);
            return Ok(())
        }
        // Create new dir under VOLUME_BASEDIR
        debug!("Creating dir for volume: {vol_path}");
        if !dry_run {
            if let Err(e) = create_dir_all(&vol_path) {
                return Err(e.to_string());
            }
        }

        let vol = Volume {
            path: vol_path,
            created: true,
            usage: 1
        };
        self.volume_list.insert(volume_name_hash, vol);
        Ok(())
    }

    fn clean_volumes(&mut self, volumes: &HashSet<&str>, opts: &WorkflowOptions) -> Result<(), String> {
        for volume_name in volumes {
            let volume_name_hash = create_hash(volume_name);
            if let Some(vol) = self.volume_list.get_mut(&volume_name_hash) {
                if vol.usage > 1 {
                    debug!("Volume {volume_name} is shared volume, decreasing usage");
                    vol.usage -= 1;
                    continue;
                }
                if vol.created {
                    debug!("Removing files for volume {volume_name}");
                    if !opts.dry_run {
                        if let Err(e) = remove_dir_all(&vol.path) {
                            return Err(e.to_string());
                        }
                    }
                }
                self.volume_list.remove(&volume_name_hash);
                continue;
            }
            return Err(format!("Volume mapping not found for volume {volume_name}"))
        }
        Ok(())
    }
}