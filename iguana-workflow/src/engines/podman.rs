use log::debug;
/// Podman container engine
use std::collections::{HashMap, HashSet};
use std::path::Path;
use std::process::Command;

use super::{Availability, ContainerOps, ImageOps, VolumeOps, CRun};
use crate::workflow::{Container, WorkflowOptions};

pub struct Podman;

const PODMAN_BIN: &str = "/usr/bin/podman";

impl Availability for Podman{
    fn is_available() -> Result<(), ()> {
        if Path::is_file(Path::new(PODMAN_BIN)) {
            return Ok(())
        };
        return Err(())
    }
}

impl ImageOps for Podman {
    fn prepare_image(&self, image: &str, dry_run: bool) -> Result<(), String> {
        let mut podman = Command::new(PODMAN_BIN);
        let cmd = podman.args(["image", "pull", "--tls-verify=false", "--", image]);

        debug!("{cmd:?}");
        if !dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }

    /// Clean container images
    fn clean_image(&self, image: &str, opts: &WorkflowOptions) -> Result<(), String> {
        if opts.debug {
            debug!("Not cleaning job image {image} because of debug option");
            return Ok(());
        }

        let mut podman = Command::new(PODMAN_BIN);
        let cmd = podman.args(["image", "rm", "--force", "--", image]);
        debug!("{cmd:?}");
        if !opts.dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }
}

impl VolumeOps for Podman {
    fn prepare_volume(&self, name: &str, opts: &WorkflowOptions) -> Result<(), String> {
        let mut podman = Command::new(PODMAN_BIN);
        let cmd = podman.args(["volume", "exists", name]);
        debug!("{cmd:?}");
        if !opts.dry_run {
            match cmd.status() {
                Ok(status) => {
                    if status.success() {
                        return Ok(());
                    }
                }
                Err(e) => {
                    return Err(e.to_string());
                }
            }
        }

        let mut podman = Command::new(PODMAN_BIN);
        let cmd = podman.args(["volume", "create", name]);
        debug!("{cmd:?}");
        if !opts.dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }

    fn clean_volumes(&self, volumes: &HashSet<&str>, opts: &WorkflowOptions) -> Result<(), String> {
        let mut podman = Command::new(PODMAN_BIN);
        let mut cmd = podman.args(["volume", "remove"]);
        cmd = cmd.args(volumes);
        debug!("{cmd:?}");
        if !opts.dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }
}

impl ContainerOps for Podman {
    fn run_container(
        &self,
        container: &Container,
        is_service: bool,
        env: HashMap<String, String>,
        opts: &WorkflowOptions,
    ) -> Result<(), String> {
        // Prepare volumes if specified
        let mut volumes = Vec::new();
        if container.volumes.is_some() {
            for v in container.volumes.as_ref().unwrap() {
                let src = v.split(":").take(1).collect::<Vec<_>>()[0];
                match self.prepare_volume(src, opts) {
                    Ok(()) => {
                        volumes.push(format!("--volume={v}"));
                    }
                    Err(e) => {
                        return Err(e);
                    }
                }
            }
        }
        // Run the container
        let mut podman = Command::new(PODMAN_BIN);
        let mut cmd = podman.args([
            "run",
            "--network=host",
            "--annotation=iguana=true",
            "--env=iguana=true",
            "--mount=type=bind,source=/iguana,target=/iguana",
        ]);

        // Use crun runtime via podman when available
        if CRun::is_available().is_ok() {
            
            cmd = cmd.arg("--runtime /usr/bin/crun");
        }

        if opts.privileged {
            cmd = cmd.args(["--volume=/dev:/dev", "--privileged"]);
        }

        if !volumes.is_empty() {
            cmd = cmd.args(volumes);
        }

        if is_service {
            cmd = cmd.arg("--detach");
        } else {
            cmd = cmd.arg("--interactive");
        }

        if !opts.debug {
            cmd = cmd.arg("--rm");
        }

        for (k, v) in env.iter() {
            cmd.arg(format!("--env={}={}", k, v));
        }

        cmd = cmd.args(["--", &container.image]);

        debug!("{cmd:?}");
        if !opts.dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }

    fn stop_container(&self, name: &str, opts: &WorkflowOptions) -> Result<(), String> {
        let mut podman = Command::new(PODMAN_BIN);
        let cmd = podman.args(["container", "stop", "--ignore", "--", name]);
        debug!("{cmd:?}");
        if !opts.dry_run {
            if let Err(e) = cmd.status() {
                return Err(e.to_string());
            }
        }
        Ok(())
    }
}
