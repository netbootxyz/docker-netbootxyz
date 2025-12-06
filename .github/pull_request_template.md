## Description
<!-- Describe your changes in detail -->

## Type of Change
<!-- Mark the relevant option with an 'x' -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Dependency update

## Related Issues
<!-- Link to related issues, e.g., "Fixes #123" or "Relates to #456" -->

## Testing
<!-- Describe how you tested your changes -->

### Test Environment
- [ ] Docker
- [ ] Podman (rootless)
- [ ] Docker Compose
- [ ] Other: ___________

### Platforms Tested
- [ ] linux/amd64
- [ ] linux/arm64

### Test Scenarios
- [ ] Standard volume mount
- [ ] NFS volume mount
- [ ] Custom PUID/PGID
- [ ] SELinux enabled
- [ ] Other: ___________

### Test Results
```
# Paste relevant test output or logs
```

## Test Images
<!-- Automated test images will be built and commented on this PR -->
Once the build completes, test images will be available:
- `netbootxyz/netbootxyz:pr-{number}`
- `ghcr.io/netbootxyz/netbootxyz:pr-{number}`

See the auto-generated comment below for pull and test commands.

## Checklist
- [ ] My code follows the style of this project
- [ ] I have tested my changes locally
- [ ] I have tested the automated PR build image
- [ ] I have updated documentation (if applicable)
- [ ] My changes generate no new errors or warnings
- [ ] I have added comments to complex code sections

## Additional Notes
<!-- Any additional information that reviewers should know -->
