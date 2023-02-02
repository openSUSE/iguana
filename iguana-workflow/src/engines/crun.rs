use log::debug;
/// crun container engine
use std::collections::{HashMap, HashSet};
use std::path::Path;
use std::process::Command;

use super::{Availability, ContainerOps, ImageOps, VolumeOps};
use crate::workflow::{Container, WorkflowOptions};

use crate::engines::skopeo::Skopeo;

use super::local_volumes::LocalVolumes;

pub struct CRun;

const CRUN_BIN: &str = "/usr/bin/crun";

impl Availability for CRun{
    fn is_available() -> Result<(), ()> {
        if Path::is_file(Path::new(CRUN_BIN)) {
            return Ok(())
        };
        return Err(())
    }
}

impl ImageOps for CRun {
    fn clean_image(&mut self, image: &str, opts: &WorkflowOptions) -> Result<(), String> {
        let mut skopeo = Skopeo::new();
        return skopeo.clean_image(image, opts)
    }
    fn prepare_image(&mut self, image: &str, dry_run: bool) -> Result<(), String> {
        let mut skopeo = Skopeo::new();
        return skopeo.prepare_image(image, dry_run)
    }
}

impl VolumeOps for CRun {
    fn clean_volumes(&mut self, volumes: &HashSet<&str>, opts: &WorkflowOptions) -> Result<(), String> {
        let mut local_volumes = LocalVolumes::new();
        return local_volumes.clean_volumes(volumes, opts)
    }

    fn prepare_volume(&mut self, volume_src: &str, opts: &WorkflowOptions) -> Result<(), String> {
        let mut local_volumes = LocalVolumes::new();
        return local_volumes.prepare_volume(volume_src, opts)
    }
}

impl ContainerOps for CRun {
    fn run_container(
        &mut self,
        container: &Container,
        is_service: bool,
        env: HashMap<String, String>,
        opts: &WorkflowOptions,
    ) -> Result<(), String> {
        Err("Not implemented".to_string())
    }

    fn stop_container(&mut self, name: &str, opts: &WorkflowOptions) -> Result<(), String> {
        Err("Not implemented".to_string())
    }
}