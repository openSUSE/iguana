use log::debug;
use std::collections::HashSet;
use std::process::Command;

use super::{Availability, VolumeOps};
use crate::workflow::WorkflowOptions;

pub struct LocalVolumes;

impl Availability for LocalVolumes{
    fn is_available() -> Result<(), ()> {
        return Ok(())
    }
}

impl VolumeOps for LocalVolumes {
    fn prepare_volume(&self, name: &str, opts: &WorkflowOptions) -> Result<(), String> {
        Err("Not implemented".to_string())
    }

    fn clean_volumes(&self, volumes: &HashSet<&str>, opts: &WorkflowOptions) -> Result<(), String> {
        Err("Not implemented".to_string())
    }
}