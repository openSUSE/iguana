/// Container engines traits
use std::collections::{HashMap, HashSet};

use crate::workflow::{Container, WorkflowOptions};

pub(crate) mod podman;

pub trait ImageOps {
    fn prepare_image(&self, image: &str, dry_run: bool) -> Result<(), String>;
    fn clean_image(&self, image: &str, opts: &WorkflowOptions) -> Result<(), String>;
}

pub trait VolumeOps {
    fn prepare_volume(&self, volume_src: &str, opts: &WorkflowOptions) -> Result<(), String>;
    fn clean_volumes(&self, volumes: &HashSet<&str>, opts: &WorkflowOptions) -> Result<(), String>;
}
pub trait ContainerOps {
    fn run_container(
        &self,
        container: &Container,
        is_service: bool,
        env: HashMap<String, String>,
        opts: &WorkflowOptions,
    ) -> Result<(), String>;
    fn stop_container(&self, name: &str, opts: &WorkflowOptions) -> Result<(), String>;
}

// pub fn get_engine() -> dyn ContainerOps {
//     let podman = Podman;
//     return podman;
// }