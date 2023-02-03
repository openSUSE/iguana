/// CRun container engine implementation
///
/// Requires skopeo and local_volumes engines

use log::debug;
use std::collections::{HashMap, HashSet};
use std::path::Path;
use std::process::Command;

use crate::workflow::{Container, WorkflowOptions};

use super::{Availability, ContainerOps, ImageOps, VolumeOps};
use super::skopeo::Skopeo;
use super::local_volumes::LocalVolumes;

pub struct CRun;

const CRUN_BIN: &str = "/usr/bin/crun";

impl Availability for CRun{
    fn is_available() -> Result<(), ()> {
        debug!("Checking crun availability");
        if Skopeo::is_available().is_err() {
            return Err(())
        };

        if LocalVolumes::is_available().is_err() {
            return Err(())
        };

        if Path::is_file(Path::new(CRUN_BIN)) {
            debug!("crun is available");
            return Ok(())
        };
        debug!("crun binary not available");
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