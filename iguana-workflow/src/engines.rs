/// Container engines traits
use std::{collections::{HashMap, HashSet}};

use crate::workflow::{Container, WorkflowOptions};

use self::{podman::Podman, crun::CRun, skopeo::Skopeo};

pub(crate) mod podman;

pub(crate) mod crun;
pub(crate) mod skopeo;
pub(crate) mod local_volumes;

pub trait Availability {
    fn is_available() -> Result<(), ()>;
}

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

pub trait ContainerEngine: ImageOps + VolumeOps + ContainerOps {}
impl<T: Availability + ImageOps + VolumeOps + ContainerOps> ContainerEngine for T {}

pub fn get_engine() -> Result<Box<dyn ContainerEngine>, String> {
    let has_skopeo = match Skopeo::is_available() {
        Ok(()) => true,
        Err(()) => false
    };

    // Check both skopeo and crun. We will need skopeo also in future runc standalone support
    if has_skopeo && CRun::is_available().is_ok() {
        return Ok(Box::new(CRun));
    }
    // if has_skopeo && Runc::is_avaiable().isok() {
    //     return Ok(Box::new(RunC));
    // }
    if Podman::is_available().is_ok() {
        return Ok(Box::new(Podman));
    }
    return Err("No supported container engine found!".to_string());
}