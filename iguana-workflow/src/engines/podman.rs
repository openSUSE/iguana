use log::debug;
/// Podman container engine
use std::collections::{HashMap, HashSet};
use std::fs;
use std::path::Path;
use std::process::Command;

use crate::engines::{ContainerOps, ImageOps, VolumeOps};
use crate::workflow::{Container, WorkflowOptions};

pub struct Podman;

impl ImageOps for Podman {
    fn prepare_image(&self, image: &str, dry_run: bool) -> Result<(), String> {
        let mut podman = Command::new("podman");
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

        let mut podman = Command::new("podman");
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
        let mut podman = Command::new("podman");
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

        let mut podman = Command::new("podman");
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
        let mut podman = Command::new("podman");
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
                if src.starts_with("/") {
                    // Volume is local directory, check if exists and create if not
                    debug!("Volume {} is a local file/directory.", src);
                    if !Path::exists(Path::new(&src)) {
                        debug!("Local volume {} does not exists, creating it as directory.", src);
                        match fs::create_dir_all(&src) {
                            Ok(_) => {}
                            Err(e) => {
                                return Err(e.to_string());
                            }
                        }
                    }
                }
                else {
                    // Volume is named volume, prepare it in advance
                    match self.prepare_volume(src, opts) {
                        Ok(_) => {}
                        Err(e) => {
                            return Err(e);
                        }
                    }
                }
                volumes.push(format!("--volume={v}"));
            }
        }
        // Run the container
        let mut podman = Command::new("podman");
        let mut cmd = podman.args([
            "run",
            "--network=host",
            "--annotation=iguana=true",
            "--env=iguana=true",
            "--mount=type=bind,source=/iguana,target=/iguana",
        ]);

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
        let mut podman = Command::new("podman");
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
